# A page per tag, generated from whatever the recipes actually declare.
#
# Two reasons this exists, both of them SEO. First, "vegetarian recipes" and
# "make-ahead recipes" are things people search for, and until now the site had
# no page that was about either — only 29 pages each about one dish. Second,
# every recipe was a leaf: nothing linked to it but the home page, so link
# equity and crawl depth had one path in. Tags turn a flat list into a graph.
#
# Generated rather than checked in as 30-odd stub files so that adding a tag to
# a recipe is all it ever takes — no second place to remember to update.

module TheLatentLarder
  class TagPageGenerator < Jekyll::Generator
    safe true
    priority :low

    BASE = "recipes/tag".freeze

    def generate(site)
      tags = collect(site)

      # Exposed to templates as `site.data.recipe_tags` so the home page and
      # the tag index can list them without recomputing the grouping.
      site.data["recipe_tags"] = tags.map do |slug, group|
        {
          "slug"  => slug,
          "name"  => group[:name],
          "count" => group[:recipes].length,
          "url"   => "/#{BASE}/#{slug}/",
        }
      end

      tags.each do |slug, group|
        site.pages << TagPage.new(site, slug, group[:name], group[:recipes])
      end

      site.pages << TagIndexPage.new(site) unless tags.empty?
    end

    private

    # Grouped by slug, so "Make-Ahead" and "make-ahead" would land on one page
    # rather than splitting into two thin ones.
    def collect(site)
      tags = {}

      site.collections["recipes"].docs.each do |doc|
        Array(doc.data["tags"]).each do |tag|
          slug = Jekyll::Utils.slugify(tag.to_s)
          next if slug.empty?

          tags[slug] ||= { :name => tag.to_s, :recipes => [] }
          tags[slug][:recipes] << doc
        end
      end

      tags.each_value { |g| g[:recipes].sort_by! { |d| d.data["date"] }.reverse! }
      tags.sort.to_h
    end
  end

  class TagPage < Jekyll::Page
    def initialize(site, slug, name, recipes)
      @site = site
      @base = site.source
      @dir  = File.join(TagPageGenerator::BASE, slug)
      @name = "index.html"

      process(@name)

      count = recipes.length
      noun  = count == 1 ? "recipe" : "recipes"

      self.data = {
        "layout"       => "tag",
        "tag"          => name,
        "tag_slug"     => slug,
        "recipes"      => recipes,
        "title"        => "#{titleize(name)} recipes",
        "description"  => "#{count} #{noun} tagged #{name} in The Latent Larder — " \
                          "ingredients, method, and the notes that matter.",
        # These pages are indexable and useful, but they are lists of links,
        # not the thing itself. WebPage keeps them from competing with the
        # recipes for the same queries as if they were content.
        "seo"          => { "type" => "CollectionPage" },
      }
    end

    # "make-ahead" -> "Make-ahead". Only the first letter: title-casing every
    # word turns "Make-Ahead" into something no one types into a search box.
    def titleize(name)
      name.sub(/\A(.)/) { Regexp.last_match(1).upcase }
    end
  end

  class TagIndexPage < Jekyll::Page
    def initialize(site)
      @site = site
      @base = site.source
      @dir  = TagPageGenerator::BASE
      @name = "index.html"

      process(@name)

      self.data = {
        "layout"      => "tag-index",
        "title"       => "Recipes by tag",
        "description" => "Every recipe in The Latent Larder, grouped by what it is " \
                         "and how it cooks.",
        "seo"         => { "type" => "CollectionPage" },
      }
    end
  end
end
