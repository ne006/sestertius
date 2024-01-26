# frozen_string_literal: true

module APIHelper
  def last_response_json
    JSON.parse(last_response.body)
  end
end
