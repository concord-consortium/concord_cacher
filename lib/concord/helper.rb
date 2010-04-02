module ::Concord::Helper
  def write_property_map(filename, hash_map)
    File.open(filename, "w") do |f|
      f.write('<?xml version="1.0" encoding="UTF-8"?>' + "\n")
      f.write('<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">' + "\n")
      f.write('<properties>' + "\n")
      hash_map.each do |url,hash|
        f.write("<entry key='#{CGI.escapeHTML(url)}'>#{hash}</entry>\n")
      end
      f.write('</properties>' + "\n")
      f.flush
    end
  end
end