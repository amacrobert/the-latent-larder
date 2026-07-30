# Pagination for the two things that list recipes: the home page and each tag
# page.
#
# Not jekyll-paginate. That gem only ever paginates `posts`, and every recipe
# here is a collection document — the same mismatch that left /feed.xml empty
# before it was written by hand. jekyll-paginate-v2 does handle collections, but
# it is a large dependency for a site that needs one list split in two, and it
# wants control of the layouts to do it.
#
# What templates see is `page.pagination`: the slice of recipes to render, plus
# everything needed to draw the links between pages. Page one lives at the
# list's own URL and the rest hang off it as /page/2/, /page/3/ — so the home
# page stays "/" and a tag stays /recipes/tag/main/ no matter how many recipes
# accumulate behind them.

module TheLatentLarder
  module Pagination
    DEFAULT_PER_PAGE = 60

    module_function

    def per_page(site)
      size = site.config["paginate"].to_i
      size.positive? ? size : DEFAULT_PER_PAGE
    end

    # Newest first, by the whole timestamp — recipes are published several times
    # a day, and a date alone would leave every one of a day's recipes tied.
    #
    # The path still breaks ties, for the two seed recipes that predate the
    # nightly run and sit at midnight, and for anything hand-written without a
    # time. sort_by alone is not stable, and unbroken ties could order
    # differently between builds, which across a page boundary means a recipe
    # appearing twice or not at all.
    def by_date_desc(docs)
      docs.sort_by { |doc| [doc.data["date"], doc.path] }.reverse
    end

    def total_pages(items, per_page)
      [(items.length.to_f / per_page).ceil, 1].max
    end

    # Page one is the list itself, not /page/1/. Two URLs for one page of
    # results is a duplicate, and the canonical one is the one people link to.
    def path(base, number)
      number <= 1 ? base : "#{base}page/#{number}/"
    end

    # Everything a template needs, precomputed. `pages` in particular: building
    # the numbered links in Liquid would mean a range, an offset, and a
    # comparison per iteration, which is a lot of template for a list of
    # numbers.
    def build(items, per_page, number, base)
      total = total_pages(items, per_page)

      {
        "page"          => number,
        "per_page"      => per_page,
        "total_pages"   => total,
        "total_items"   => items.length,
        "items"         => items[(number - 1) * per_page, per_page] || [],
        "previous_page" => (number - 1 if number > 1),
        "previous_path" => (path(base, number - 1) if number > 1),
        "next_page"     => (number + 1 if number < total),
        "next_path"     => (path(base, number + 1) if number < total),
        "pages"         => (1..total).map do |n|
          { "number" => n, "path" => path(base, n), "current" => n == number }
        end,
      }
    end
  end

  # The home page is a source file, so page one is the file itself with a
  # `pagination` key added; only the continuations have to be generated.
  class HomePagination < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      home = site.pages.find { |page| page.data["layout"] == "home" }
      return if home.nil?

      recipes  = Pagination.by_date_desc(site.collections["recipes"].docs)
      per_page = Pagination.per_page(site)
      base     = home.url

      # Copied before page one gets its own `pagination`, so the continuations
      # inherit the front matter — the layout, the section heading — and
      # nothing else.
      front_matter = home.data.dup

      (2..Pagination.total_pages(recipes, per_page)).each do |number|
        site.pages << ContinuationPage.new(
          site, home, front_matter, number,
          Pagination.build(recipes, per_page, number, base)
        )
      end

      home.data["pagination"] = Pagination.build(recipes, per_page, 1, base)
    end
  end

  class ContinuationPage < Jekyll::Page
    def initialize(site, home, front_matter, number, pagination)
      @site = site
      @base = site.source
      @dir  = File.join("page", number.to_s)
      @name = "index.html"

      process(@name)

      # The same body as page one. The layout decides what of it to show —
      # the intro paragraph is page one's alone, because the same prose at two
      # URLs is two pages competing to be the front door.
      self.content = home.content

      self.data = front_matter.merge(
        # Page one has no title of its own, so seo-tag titles it with the site.
        # A continuation needs its own, or every page of the list arrives in
        # search results calling itself the home page.
        "title"      => "Recipes, page #{number}",
        "pagination" => pagination,
      )
    end
  end
end
