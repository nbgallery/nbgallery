require 'test_helper'

# :nodoc:
class NotebookMailerTest < ActionMailer::TestCase
  test 'share' do
    mail = NotebookMailer.share
    assert_equal 'Share', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'feedback' do
    mail = NotebookMailer.feedback
    assert_equal 'Feedback', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end
end
