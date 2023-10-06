require 'test_helper'

# :nodoc:
class ChangeRequestMailerTest < ActionMailer::TestCase
  setup do
    @change_request = change_requests(:one)
    @user = users(:one)
  end

  test 'create' do
    mail = ChangeRequestMailer.create(@change_request, '')
    assert_equal 'Create', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'cancel' do
    mail = ChangeRequestMailer.cancel(@change_request, '')
    assert_equal 'Cancel', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'decline' do
    mail = ChangeRequestMailer.decline(@change_request, @user, '')
    assert_equal 'Decline', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end

  test 'accept' do
    mail = ChangeRequestMailer.accept(@change_request, @user, '')
    assert_equal 'Accept', mail.subject
    assert_equal ['to@example.org'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match 'Hi', mail.body.encoded
  end
end
