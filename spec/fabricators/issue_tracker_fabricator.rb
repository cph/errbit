Fabricator :issue_tracker do
  app
  api_token "some-token"
  project_id { sequence :word }
  account "account-name"
  username "johnsoda"
  password "password"
end

%w(pivotal_labs fogbugz).each do |t|
  Fabricator "#{t}_tracker".to_sym, from: :issue_tracker, class_name: "IssueTrackers::#{t.camelcase}Tracker"
end

Fabricator :gitlab_tracker, from: :issue_tracker, class_name: "IssueTrackers::GitlabTracker" do
  account 'http://gitlab.example.com'
  alt_project_id 'foo'
end

Fabricator :mingle_tracker, from: :issue_tracker, class_name: "IssueTrackers::MingleTracker" do
  account 'https://mingle.example.com'
  ticket_properties 'card_type = Defect, defect_status = open, priority = essential'
end

Fabricator :github_issues_tracker, from: :issue_tracker, class_name: "IssueTrackers::GithubIssuesTracker" do
  project_id 'test_account/test_project'
  username 'test_username'
end

Fabricator :bitbucket_issues_tracker, from: :issue_tracker, class_name: "IssueTrackers::BitbucketIssuesTracker" do
  project_id 'password'
  api_token 'test_username'
end

Fabricator :unfuddle_issues_tracker, from: :issue_tracker, class_name: "IssueTrackers::UnfuddleTracker" do
  account 'test'
  project_id 15
end
