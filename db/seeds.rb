dhh = User.create!(
  github_username: 'dhh',
  email:           'dhh@rails.com',
  password:        'servestew',
  token:           '1ea7ca751ea7ca751ea7ca751ea7ca75',
  uid:             '1ea7ca75',
  provider:        'github'
)

repository = Repository.create!(
  name:           'rails/rails',
  webhook_secret: 'whatever',
  access_via:     dhh
)

pull_request1 = PullRequest.create!(
  title:      "Put the Ruby on the Rails.",
  repository: repository,
  number:     11,
  html_url:   'https://github.com/rails/rails/pulls/11'
)

notification1 = Notification.create!(
  pull_request: pull_request1
)
notification1.notified_users << dhh
notification1.save!

pull_request2 = PullRequest.create!(
  title:      "Put the Rails on the Unicorn.",
  repository: repository,
  number:     12,
  html_url:   'https://github.com/rails/rails/pulls/12'
)

notification2 = Notification.create!(
  pull_request: pull_request2
)
notification2.notified_users << dhh
notification2.save!
