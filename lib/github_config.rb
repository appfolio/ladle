class GithubConfig
  attr_reader :application_id, :application_secret

  def initialize(application_id:, application_secret:, restrict_access_to_organizations: nil)
    @application_id                   = application_id
    @application_secret               = application_secret
    @restrict_access_to_organizations = restrict_access_to_organizations
  end

  def self.from_file(config_file)
    values = YAML.load_file(config_file)
    new(application_id:                   values["github_application"]["application_id"],
        application_secret:               values["github_application"]["application_secret"],
        restrict_access_to_organizations: values["restrict_access_to_organizations"])
  end

  def organization_permitted?(organizations)
    if @restrict_access_to_organizations
      !(@restrict_access_to_organizations & organizations).empty?
    else
      true
    end
  end
end
