require 'active_record'

module I18n
  module Backend
    class Releaf
      class TranslationData < ::ActiveRecord::Base

        self.table_name = "releaf_translation_data"

        validates_presence_of :translation_id, :lang
        validates_uniqueness_of :translation_id, :scope => :lang

        belongs_to :translation

        attr_accessible \
          :lang,
          :localization,
          :translation_id

        scope :available_locales, where('lang IS NOT NULL').group(:lang).pluck(:lang)

        after_commit :reload_cache

        def text
          self[:localization].blank? == false ? self[:localization] : self.translation.try(:key).try(:humanize)
        end

        private

        def reload_cache
          Settings.i18n_updated_at = Time.now
          I18n.backend.reload_cache
        end

      end
    end
  end
end
