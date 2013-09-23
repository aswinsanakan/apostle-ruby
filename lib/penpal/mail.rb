require 'net/http'
require 'json'

module Penpal

  class Mail

    attr_accessor :data,
      :email,
      :from,
      :headers,
      :layout_id,
      :name,
      :reply_to,
      :template_id,
      :_exception

    def initialize(template_id, options = {})
      @template_id = template_id
      @data = {}

      options.each do |k, v|
        self.send("#{k}=", v)
      end
    end

    # Provide a getter and setters for headers
    def header(name, value = nil)
      if value
        (@headers ||= {})[name] = value
      else
        (@headers || {})[name]
      end
    end

    # Allow convenience setters for the data payload
    # E.G. mail.potato= "Something" will set @data['potato']
    def method_missing(method, *args)
      return unless method.match /.*=/
      @data[method.to_s.gsub(/=$/, '')] = args.first
    end

    def deliver
      begin
        deliver!
        true
      rescue DeliveryError => e
        false
      end
    end

    # Shortcut method to deliver a single message
    def deliver!
      unless template_id && template_id != ""
        raise DeliveryError,
          "No email template_id provided"
      end

      queue = Penpal::Queue.new
      queue.add self
      results = queue.deliver!

      # Return true or false depending on successful delivery
      if results[:valid].include?(self)
        return true
      else
        raise _exception
      end
    end

    def to_h
      {
        "#{self.email.to_s}" => {
          "data" => @data,
          "from" => from.to_s,
          "headers" => headers,
          "layout_id" => layout_id.to_s,
          "name" => name.to_s,
          "reply_to" => reply_to.to_s,
          "template_id" => template_id.to_s
        }.delete_if { |k, v| !v || v == '' }
      }
    end

    def to_json
      JSON.generate(to_h)
    end
  end
end