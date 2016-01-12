class Releaf::Builders::Page::HeaderBuilder
  include Releaf::Builders::Base
  include Releaf::Builders::Template

  def output
    safe_join do
      items
    end
  end

  def items
    [home_link, profile_block, sign_out_form]
  end

  def home_link
    tag(:a, class: "home", href: home_url) do
      image_tag(home_image_path, alt: home_text)
    end
  end

  def home_url
    url_for(:releaf_root)
  end

  def home_text
    "Releaf"
  end

  def home_image_path
    "releaf/logo.png"
  end

  def profile_url
    url_for(action: 'edit', controller: profile_controller)
  end

  def profile_settings_url
    url_for(action: 'settings', controller: profile_controller)
  end

  def profile_controller
    "/releaf/permissions/profile"
  end

  def profile_block
    tag(:a, class: "button profile", href: profile_url, "data-settings-url" => profile_settings_url) do
      [tag(:span, profile_user_name, class: "name")]
    end
  end

  def user
    access_control.user
  end

  def profile_user_name
    user.to_text
  end

  def sign_out_url
    url_for(action: 'destroy', controller: "/releaf/permissions/sessions")
  end

  def sign_out_form
    form_tag(sign_out_url, method: :delete, class: "sign-out") do
      tag(:button, class: "button only-icon", type: "submit", title: t('Sign out', scope: "admin.sessions")) do
        icon("power-off icon-header")
      end
    end
  end
end
