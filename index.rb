#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fast_stemmer'

#h1 = {0.html:[error],b:2,c:3}
#h1.except!(:a)
#print h1
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end


# function that takes the name of a file and loads in the stop words from the file.
#  You could return a list from this function, but a hash might be easier and more efficient.
#  (Why? Hint: think about how you'll use the stop words.)
#
def load_stopwords_file(filename) 
  myfile = File.open(filename, "r")
  lines = myfile.readlines
  word_list = []
  for x in lines
    words = x.split(/[\n]/)
    for y in words
      word_list.push(y)
    end
  end
  myfile.close()
  hash = word_list.map{|k| [k,0]}
  hash1 = Hash[hash]
  return hash1
end



# function that takes the name of a directory, and returns a list of all the filenames in that
# directory.
# http://stackoverflow.com/questions/1755665/get-names-of-all-files-from-a-folder-with-ruby
def list_files(dir)
  m = Dir.entries(dir).select {|f| !File.directory? f}
  return m
end


# function that takes the *name of an html file stored on disk*, and returns a list
#  of tokens (words) in that file. 
#http://stackoverflow.com/questions/4190797/how-can-i-remove-the-string-n-from-within-a-ruby-string
def find_tokens(filename)
  word_list = []
  rr = Nokogiri::HTML(open(filename))
  rr.css('script, style').each { |node| node.remove }
  words = rr.css('body').text.encode!('UTF-8', :invalid=>:replace).split(/[ ,\-,\n,\r,\t,&]/)

  #words = rr.css('body').text.split(/[ ,\-,\n,\r,\t,&]/)
  words.each {|w| word_list.push(w)}
  word_list.reject!{|c| c.empty?}
  return word_list
end

# function that takes a list of tokens, and a list (or hash) of stop words,
#  and returns a new list with all of the stop words removed
#
def remove_stop_tokens(tokens, stop_words)
  tokens_without_stop = Array.new

  tokens.each do |token|
    unless stop_words.include? token
      tokens_without_stop.push(token)
    end
  end

  return tokens_without_stop
end
# function that takes a list of tokens, runs a stemmer on each token,
#  and then returns a new list with the stems
#
def stem_tokens(tokens)
  stem_tokens = Array.new

  tokens.each do |token|
    stem_tokens.push(Stemmer.stem_word(token))
  end
  
  return stem_tokens
end

def invindex(tokens,mm)
  total_hash = {}
  for x in tokens
    for y in x
      if not total_hash.has_key?(y)
      total_hash[y] = {}
      end
    end
  end
 
  term = total_hash.keys
  for a in term
    for b in tokens
      ct = b.count(a)
      if not ct == 0
      page = mm[tokens.index(b)]
      total_hash[a][page] = ct
      end
    end
  end
 new_hash = {}
 total_hash.each {|k,v|
   l = total_hash[k].length
   new_hash[k] = [l,total_hash[k]]
 }
  return new_hash
end
#runtimeerror       http://stackoverflow.com/questions/2229223/rescue-runtimeerror-in-rake
#404 error          http://stackoverflow.com/questions/18270596/how-to-handle-404-not-found-errors-in-nokogiri
#handle multiple error http://mikeferrier.com/2012/05/19/rescuing-multiple-exception-types-in-ruby-and-binding-to-local-variable/
=begin
def docs(tokens,mm,newhash)
  t_hash = {}
  for x in mm
    t_hash[x] = []
  end

    for b in tokens
      ct = b.length
      page = mm[tokens.index(b)]
      url = newhash[page]
      begin
      title = Nokogiri::HTML(open(url)).css("title").text.split(/[ ,\-,\n,\r,\t,&]/).join("")
      t_hash[page] = [ct,title,url]
      rescue RuntimeError,OpenURI::HTTPError
      t_hash[page] = ["error"]
      end
    end
 
  return t_hash
end
=end

def docs(tokens,mm,newhash)                                                     
  t_hash = {}                                                                   
  for x in mm                                                                   
    t_hash[x] = []                                                              
  end                                                                           
      for b in tokens                                                             
        ct = b.length                                                             
        page = mm[tokens.index(b)]                                                
        url = newhash[page]                                                       
        begin                                                                     
          title = Nokogiri::HTML(open(url)).css("title").text.split(/[\-,\n,\r,\t,&]/).join("")
          t_hash[page] = [ct,title,url]                                             
        rescue Exception=>e#RuntimeError,OpenURI::HTTPError                        
          t_hash[page] = ["error"]                                                  
        end                                                                       
      end                                                                                             
  return t_hash                                                                 
end         
def load_dat (filename)
  myfile = File.open(filename, "r")
  lines = myfile.readlines
  word_list = []
  for x in lines
    words = x.split(/[\n]/)
     for y in words
      word_list.push(y.gsub(/\s+/m, ' ').strip.split(" "))
     end
  end
  myfile.close()
  return word_list
end

def list_to_hash(word_list)
  newhash = {}
  for x in word_list
    keya = x[0]
    valuea = x[1]
    newhash[keya] = valuea
    end
return newhash
end

#
# You'll likely need other functions. Add them here!
#

#################################################
# Main program. We expect the user to run the program like this:
#
#   ruby index.rb pages_dir/ index.dat
#

# The following is just a main program to help get you started.
# Feel free to make any changes or additions/subtractions to this code.
#

# check that the user gave us 3 command line parameters
if ARGV.size != 2

  abort "Command line should have 3 parameters."
end

# fetch command line parameters
(pages_dir, index_file) = ARGV

# read in list of stopwords from file
stopwords = load_stopwords_file("stop.txt")

# get the list of files in the specified directory
file_list = list_files(pages_dir)

# create hash data structures to store inverted index and document index
#  the inverted index, and the outgoing links
# scan through the documents one-by-one
total_tokens = [] 
file_list.each do |doc_name|
  print "Parsing HTML document: #{doc_name} \n";
  ppp = "page/"+ doc_name   
  tokens = find_tokens(ppp)
  tokens = remove_stop_tokens(tokens, stopwords)
  tokens = stem_tokens(tokens)
  total_tokens = total_tokens.push(tokens)     
end

dat = load_dat(index_file)
dat2 = list_to_hash(dat)

ye = invindex(total_tokens,file_list)
yu = docs(total_tokens,file_list,dat2)  
ys = write_data('invindex.dat',ye)
yy = write_data('docs.dat',yu)
print "Indexing complete!\n";
