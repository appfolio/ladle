class GithubConfig
  attr_reader :application_id, :application_secret

  def initialize(application_id:, application_secret:, restrict_access_to_organizations: nil)
    @application_id                   = application_id
    @application_secret               = application_secret
    @restrict_access_to_organizations = restrict_access_to_organizations
  end

  def self.from_values(config_hash)
    new(application_id:                   config_hash["github_application"]["application_id"],
        application_secret:               config_hash["github_application"]["application_secret"],
        restrict_access_to_organizations: config_hash["restrict_access_to_organizations"]&.split(','))
  end

  def organization_permitted?(organizations)
    if @restrict_access_to_organizations
      !(@restrict_access_to_organizations & organizations).empty?
    else
      true
    end
  end
end
