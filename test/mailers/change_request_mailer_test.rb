require 'test_helper'

# :nodoc:
class ChangeRequestMailerTest < ActionMailer::TestCase
  test 'create' do
    mail = ChangeRequestMailer.create
    assert_equal 'Create', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'cancel' do
    mail = ChangeRequestMailer.cancel
    assert_equal 'Cancel', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'decline' do
    mail = ChangeRequestMailer.decline
    assert_equal 'Decline', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'accept' do
    mail = ChangeRequestMailer.accept
    assert_equal 'Accept', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end
end
