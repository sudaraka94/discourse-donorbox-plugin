# name: discourse-donorbox-plugin
# about: A plugin to sync discourse with Donor Box
# version: 0.1
# authors: Sudaraka Jayathilaka
# url: https://github.com/sudaraka94/discourse-donorbox-plugin

enabled_site_setting :donorbox_enabled

module ::OpencollectivePlugin
  BADGE_NAME ||= SiteSetting.donorbox_badge_name.freeze

  def self.badges_grant!(user)
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: SiteSetting.donorbox_badge_description,
                           badge_type_id: 1)
    end
    BadgeGranter.grant(badge, user)
  end
end

after_initialize do

end
