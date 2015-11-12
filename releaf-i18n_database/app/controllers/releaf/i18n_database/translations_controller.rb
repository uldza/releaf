module Releaf::I18nDatabase
  class TranslationsController < ::Releaf::BaseController
    def self.resource_class
      Releaf::I18nDatabase::Translation
    end

    def edit
      @collection = resources
      search(params[:search])
    end

    def export
      @collection = resources
      search(params[:search])

      respond_to do |format|
        format.xlsx do
          response.headers['Content-Disposition'] = "attachment; filename=\"#{export_file_name}\""
        end
      end
    end

    def build_breadcrumbs
      super

      if %w[edit update].include?(params[:action]) && !params.has_key?(:import)
        @breadcrumbs << { name: I18n.t("edit translations", scope: controller_scope_name), url: url_for(action: :edit, search: params[:search]) }
      end
    end

    def update
      @collection = []
      @translations_to_save = []

      valid = build_updatables(params[:translations])
      import_view if params.has_key?(:import)

      respond_to do |format|
        format.html do
          if valid
            process_updatables
            update_response_success
          else
            render_notification false, now: true
            render action: :edit
          end
        end
      end
    end

    def resources
      Releaf::I18nDatabase::TranslationsUtilities.include_localizations(super).order(:key)
    end

    # overwrite search here
    def search(lookup_string)
      @collection = Releaf::I18nDatabase::TranslationsUtilities.search(@collection, lookup_string, params[:only_blank].present?)
    end

    def import
      if File.exists?(import_file_path) && !import_file_extension.blank?
        begin
          @collection = Releaf::I18nDatabase::TranslationsImporter.new(import_file_path, import_file_extension).parsed_output
          import_view
          render :edit
        rescue Releaf::I18nDatabase::TranslationsImporter::UnsupportedFileFormatError
          flash["error"] = { "id" => "resource_status", "message" => I18n.t("Unsupported file format", scope: notice_scope_name) }
          redirect_to action: :index
        end
      else
        redirect_to action: :index
      end
    end

    def searchable_fields
      true
    end

    def import_view
      @import = true
      @breadcrumbs << { name: I18n.t("import", scope: controller_scope_name) }
    end

    def setup
      super
      @features = {
        index: true
      }
    end

    def action_features
      {
        index: :index,
      }.with_indifferent_access
    end

    private

    def process_updatables
      resource_class.where(id: @translation_ids_to_destroy).destroy_all unless @translation_ids_to_destroy.empty?
      @translations_to_save.map(&:save!)
      Releaf::I18nDatabase::Backend.translations_updated_at = Time.now
    end

    def build_updatables translations_params
      valid = true
      @translation_ids_to_destroy = params.fetch(:existing_translations, "").split(",")

      translations_params ||= []
      translations_params.each do |values|
        translation = load_translation(values["key"], values["localizations"])

        if translation.valid?
          @translations_to_save << translation
          @translation_ids_to_destroy.delete(translation.id.to_s)
        else
          valid = false
        end

        @collection << translation
      end

      valid
    end

    def load_translation(key, localizations)
      translation = Releaf::I18nDatabase::Translation.where(key: key).first_or_initialize
      translation.key = key

      localizations.each_pair do |locale, localization|
        load_translation_data(translation, locale, localization)
      end

      translation
    end

    def load_translation_data(translation, locale, localization)
      translation_data = translation.translation_data.find{ |x| x.lang == locale }
      # replace existing locale value only if new one is not blank
      if translation_data
        translation_data.localization = localization
        # always assign value for new locale
      elsif translation_data.nil?
        translation_data = translation.translation_data.build(lang: locale, localization: localization)
      end

      translation_data
    end

    def update_response_success
      if @import
        msg = 'successfuly imported %{count} translations'
        flash["success"] = { "id" => "resource_status", "message" => I18n.t(msg, default: msg, count: @translations_to_save.size , scope: notice_scope_name) }
        redirect_to action: :index
      else
        render_notification true
        redirect_to({action: :edit}.merge(request.query_parameters))
      end
    end

    def export_file_name
      "#{Rails.application.class.parent_name.underscore}_translations_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.xlsx"
    end

    def import_file_path
      params[:import_file].try(:tempfile).try(:path).to_s
    end

    def import_file_extension
      File.extname(params[:import_file].original_filename).gsub(".", "")
    end
  end
end
