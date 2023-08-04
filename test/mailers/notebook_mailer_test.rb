require 'test_helper'

# :nodoc:
class NotebookMailerTest < ActionMailer::TestCase
  setup do
    @feedback = feedbacks(:one)
    @notebook = notebooks(:one)
    @user = users(:one)
  end

  test 'share' do
    mail = NotebookMailer.share(@notebook, @user, [], '', '')
    assert_equal 'Share', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'feedback' do
    mail = NotebookMailer.feedback(@feedback, '')
    assert_equal 'Feedback', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end
end
