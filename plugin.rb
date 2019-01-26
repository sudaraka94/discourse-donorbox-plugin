# name: discourse-donorbox-plugin
# about: A plugin to sync discourse with Donorbox
# version: 0.1
# authors: Sudaraka Jayathilaka
# url: https://github.com/sudaraka94/discourse-donorbox-plugin
require 'net/http'
require 'net/https'

enabled_site_setting :donorbox_enabled

module ::DonorboxPlugin
  BADGE_NAME ||= "Donorbox Donor".freeze

  def self.badges_grant!(user)
    unless badge = Badge.find_by(name: BADGE_NAME)
      badge = Badge.create!(name: BADGE_NAME,
                           description: "Granted for the contributions made on Donorbox" ,
                           badge_type_id: 1)
    end
    BadgeGranter.grant(badge, user)
  end

  def self.seed_group!
    default_group = Group.new(
        name: "Backer",
        visibility_level: Group.visibility_levels[:public],
        primary_group: true,
        title: "Donorbox Backer",
        flair_url: "https://donorbox.org/nonprofit-blog/wp-content/uploads/2016/09/donorbox-logo-lg-square.png",
        bio_raw: "Donorbox Backers are added to this user group",
        full_name: "Donorbox Backer"
    )

    default_group.save!
    group_id=default_group.id.to_s
    ::PluginStore.set('discourse-donorbox-plugin','backer_group_id',group_id )
    return default_group
  end

  def self.add_backers_to_group!(user)
    group_id=::PluginStore.get('discourse-donorbox-plugin','backer_group_id')
    if group_id==nil
       group=seed_group!
    else
      group = Group.find_by id: group_id.to_i
      if group==nil
        group=seed_group!
      end
    end

    group.add user
  end

  def self.sync!
      access_key = SiteSetting.donorbox_access_key
      access_email = SiteSetting.donorbox_access_email

      if access_key=="" or access_email==""
        puts "Fetching users from Donorbox failed!"
        puts "Please configure settings in your admin panel"
        return
      end

      uri = URI.parse("https://donorbox.org/api/v1/donors")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(access_email, access_key)
      response = http.request(request)


      data = JSON.parse response.body
      if data==nil
        puts "Granting badges for Donorbox users failed!"
        return
      end

      # Iterates through users
      data.each do |user|
        email=user['email']
        dUser=User.find_by_email(email)

        if dUser!=nil
          badges_grant!(dUser)
          add_backers_to_group!(dUser)
        end
      end
    end
end

after_initialize do
  module ::DonorboxPlugin
      class DonoboxGrantBadgeJob < ::Jobs::Scheduled
        every 1.minute

        def execute(args)
          DonorboxPlugin.sync!
        end
      end
    end
end
