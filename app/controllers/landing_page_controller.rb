class LandingPageController < ActionController::Metal

  class Denormalizer

    def initialize(root: "composition", hooks: {})
      @root = root
      @hooks = hooks
    end

    def to_tree(normalized_data)
      root = normalized_data[@root]

      HashUtils.deep_map(root) { |k, v|
        case v
        when Hash
          type = v["type"]
          id = v["id"]

          new_v =
            if type.nil?
              # Not a link
              v
            elsif id.nil?
              # Looks like link, but no ID. That's an error.
              raise ArgumentError.new("Invalid link: #{v.inspect} has a 'type' key but no 'id'")
            else
              # Is a link
              hook(type, normalized_data[type][id])
            end

          [k, new_v]
        else
          [k, v]
        end
      }
    end

    private

    def hook(type, value)
      if @hooks[type].respond_to? :call
        @hooks[type].call(value)
      else
        value
      end
    end
  end

  # Needed for rendering
  #
  # See Rendering Helpers: http://api.rubyonrails.org/classes/ActionController/Metal.html
  #
  include AbstractController::Rendering
  include ActionView::Layouts
  append_view_path "#{Rails.root}/app/views"

  def index
    landing_page
  end

  private

  def landing_page
    denormalizer = Denormalizer.new(
      hooks: {
        "assets" => method(:append_asset_dir)
      })

    render :landing_page, locals: { sections: denormalizer.to_tree(data) }
  end

  def append_asset_dir(file)
    ["landing_page", file].join("/")
  end

  def data
    {
      "settings" => {
        "marketplace_id" => 9999,
        "locale" => "en",
        "sitename" => "turbobikes"
      },

      "sections" => {
        "myhero1" => {
          "kind" => "hero",
          "title" => "Sell your turbobike",
          "subtitle" => "The best place to rent your turbojopo",
          "background_image" => {"type" => "assets", "id" => "myheroimage"},
          "search_placeholder" => "What kind of turbojopo are you looking for?",
          "search_button" => "Search",
        },
        "thecategories" => {"type" => "categories", "slogan" => "blaablaa", "category_ids" => [123, 432, 131]},
      },

      "composition" => [
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => false},
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => false},
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => true},
      ],

      "assets" => {
        "myheroimage" => "hero.png",
      }
    }
  end
end
