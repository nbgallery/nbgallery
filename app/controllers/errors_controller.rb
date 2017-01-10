# app/controllers/error_controller.rb
class ErrorsController < ApplicationController
  # Include a few Gaffe Helpers
  include Gaffe::Errors

  # Let's use our same layout
  layout 'layout'

  def show
    # the following varibles are avaiable:
    # @exception          The encountered exception (Eg. `<ActiveRecord::NotFound..>`)
    # @status_code        The status code we should return (Eg. `404`)
    # @rescue_response    The "standard" name for the status code (Eg. `:not_found`)

    render "errors/#{@rescue_response}", code: @status_code
  end
end
