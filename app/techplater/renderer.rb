module Techplater
  class Renderer
    def initialize(template, chunks)
      @template = template
      @chunks = chunks
    end

    def render
      require 'handlebars'

      handlebars = Handlebars::Context.new
      handlebars.register_helper(:imageTag) do |context, image, style|
        begin
          [
            "<div class='img #{style}'>",
            "  <img src='#{Picture.find(image).content.url}'>",
            "  <p class='caption'>#{Picture.find(image).image.caption}</p>",
            "  <p class='attribution'>#{Picture.find(image).image.attribution}</p>",
            "</div>"
          ].join("\n")
        rescue ActiveRecord::RecordNotFound
          ''
        end
      end

      template = handlebars.compile(@template)

      template.call(chunks: @chunks)
    end
  end
end