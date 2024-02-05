# frozen_string_literal: true

require 'faraday'
require 'nokogiri'
require 'date'

module CBR
  class API
    BASE_URI = 'https://cbr.ru/'

    KeyRate = Struct.new(:date, :rate) do
      def self.from_xml(xml)
        new(Date.parse(xml.xpath('DT/text()').first.to_s), xml.xpath('Rate/text()').first.to_s.to_f)
      end
    end

    def key_rate(from: Date.today - 7, to: Date.today)
      response = soap_request('/DailyInfoWebServ/DailyInfo.asmx') do |xml|
        xml.KeyRateXML('xmlns' => 'http://web.cbr.ru/') do
          xml.fromDate from.xmlschema
          xml.ToDate to.xmlschema
        end
      end

      return false unless response

      response.xpath('//KeyRate/KR')
              .map { KeyRate.from_xml(_1) }
    end

    private

    def client
      @client ||= ::Faraday.new(BASE_URI)
    end

    def soap_request(uri, &)
      doc = block_given? ? soap_request_doc(&) : soap_request_doc

      response = client.post(uri, doc.to_xml,
                             { 'content-type' => 'application/soap+xml' })

      return false unless response.success?

      Nokogiri::XML.parse(response.body)
    end

    def soap_request_doc
      Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
        xml['soap12'].Envelope(
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:soap12' => 'http://www.w3.org/2003/05/soap-envelope'
        ) do
          xml['soap12'].Body { yield xml if block_given? }
        end
      end
    end
  end
end
