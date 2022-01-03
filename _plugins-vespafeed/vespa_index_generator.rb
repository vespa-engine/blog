# Copyright Yahoo. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'json'
require 'nokogiri'
require 'kramdown/parser/kramdown'

module Jekyll

    class VespaIndexGenerator < Jekyll::Generator
        priority :lowest

        def generate(site)
            namespace = site.config["search"]["namespace"]
            operations = []
            site.posts.docs.each do |post|
                if post.data["index"] == true
                    operations.push({
                        :fields => {
                            :path => post.url,
                            :namespace => namespace,
                            :title => post.data["title"],
                            :content => from_markdown(post),
                        }
                    })
                end
            end

            json = JSON.pretty_generate(operations)
            File.open(namespace + "_index.json", "w") { |f| f.write(json) }
        end

        def from_markdown(post)
            input = Kramdown::Document.new(post.content).to_html
            doc = Nokogiri::HTML(input)
            doc.search('th,td').each{ |e| e.after "\n" }
            doc.search('style').each{ |e| e.remove }
            content = doc.xpath("//text()").to_s
            post_text = content.gsub("\r"," ").gsub("\n"," ")
        end

    end

end
