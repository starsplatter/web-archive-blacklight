# A sample traject configuration, save as say `traject_config.rb`, then
# run `traject -c traject_config.rb marc_file.marc` to index to
# solr specified in config file, according to rules specified in
# config file


# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
require 'digest/md5'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats


# In this case for simplicity we provide all our settings, including
# solr connection details, in this one file. But you could choose
# to separate them into antoher config file; divide things between
# files however you like, you can call traject with as many
# config files as you like, `traject -c one.rb -c two.rb -c etc.rb`
settings do
  provide "solr.url", "#{ENV['SOLR_URL']}"
  provide "solr.version", "7.4.0"
  provide "nokogiri.namespaces", {
  "oai" => "http://www.openarchives.org/OAI/2.0/",
  "dc" => "http://purl.org/dc/elements/1.1/",
  "oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/"
}

provide "nokogiri.each_record_xpath", "//oai:record"

provide "solr_writer.commit_on_close", "true"

provide "log.level", "debug"

end





# Extract first 001, then supply code block to add "bib_" prefix to it


to_field "book_title_tesim", extract_xpath("/oai:record/oai:metadata/oai_dc:dc/dc:title")
to_field "wasubject_tesim", extract_xpath("/oai:record/oai:metadata/oai_dc:dc/dc:subject")
to_field "image_ocr_tesim", extract_xpath("/oai:record/oai:metadata/oai_dc:dc/dc:description")
to_field "walanguage_tesim", extract_xpath("/oai:record/oai:metadata/oai_dc:dc/dc:language")
to_field "wacoverage_tesim", extract_xpath("/oai:record/oai:metadata/oai_dc:dc/dc:coverage")
to_field "waurl_tesim", extract_xpath("/oai:record/oai:header/oai:identifier")




to_field "id", extract_xpath("/oai:record/oai:header/oai:identifier", to_text: false) do |record, accumulator|
  accumulator.map! do |xml_node|
    webid = Digest::MD5.hexdigest(xml_node)
    "#{webid}"
  end
end



to_field "wacollection_tesim", extract_xpath("/oai:record/oai:header/oai:setSpec", to_text:false) do |record,accumulator|
  accumulator.map! do |xml_node|
    set  = collection_name(xml_node.content)
  end
    
end

# curl "http://localhost:8983/solr/blacklight-core/update?commit=true" -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
# traject -i xml -r Traject::OaiPmhNokogiriReader -s oai_pmh.start_url="https://archive-it.org/oai/organizations/529?verb=ListRecords&metadataPrefix=oai_dc&set=collection:9321" -c config/traject_config.rb

def collection_name(node)
  collections = Nokogiri::XML(open('https://archive-it.org/oai/organizations/529?verb=ListSets&metadataPrefix=oai_dc'))
  collections.remove_namespaces!
  collections.xpath("//setSpec").each do |e|
    if e.text == node
      set = e.next_element.text
      return set
    end
  end
end

each_record do |record,context|
  if context.output_hash["book_title_tesim"].nil?
    context.skip!("no title")
  end
end