class GithubConfig
  attr_reader :application_id, :application_secret

  def initialize(application_id:, application_secret:)
    @application_id     = application_id
    @application_secret = application_secret
  end

  def self.from_file(config_file)
    values = YAML.load_file(config_file)
    new(application_id:     values["github_application"]["application_id"],
        application_secret: values["github_application"]["application_secret"])
  end
end
