
## reference http://www.iijlab.net/~kjc/classes/sfc2012s-measurement/pagerank.rb


#!/l/ruby-2.2.2/bin/ruby                                                                                           

require 'mechanize'
require 'fast_stemmer'
require 'logger'

def retrieve_page(url)
  begin
  agent = Mechanize.new
  agent.read_timeout = 5
  agent.log = Logger.new "mech.log"
  agent.user_agent_alias = 'Mac Safari'
  page = agent.get url
  rescue Exception
    return nil
  end
  return page
end

# function that takes HTML code as a parameter, and then                                                                                                                                                                                                                                                                                                          
# returns a list of that page's hyperlinks (URLs)                                                                                                                                                                                                                                                                                                                 
#http://stackoverflow.com/questions/6700367/getting-all-links-of-a-webpage-using-ruby                                                                                                                                                                                                                                                                             

def find_links(html_code)
  ls = []
  begin
  html_code.links_with(:href => /^https?/).each do |link|
    ls.push(link.href)
  end
    rescue Exception=>e
    puts e
    end
  ls = ls.uniq
  return ls
end




# This function writes out a hash or an array (list) to a file.
#  You can modify this function if you want, but it should already work as-is.
# 
# write_data("file1",my_hash)
# 
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# This function reads in a hash or an array (list) from a file produced by write_file().
#  You can modify this function if you want, but it should already work as-is.
# 
# my_list=read_data("file1")
# my_hash=read_data("file2")
def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets)
  file.close()
  return object
end

#
# You'll likely need other functions. Add them here!
#

# function that takes the name of a file and loads in the stop words from the file.
#  You could return a list from this function, but a hash might be easier and more efficient.
#  (Why? Hint: think about how you'll use the stop words.)
#
def load_stopwords_file(file) 
    stop_words = Hash.new(0)
    file = File.open(file, "r")
    file.readlines.each do |word|
      stop_words[word.chomp] = 1
    end

    file.close
    return stop_words
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









######



##Loop for calculating the Pagerank Score





# read in the index file produced by the crawler from Assignment 2 (mapping URLs to filenames).                    
docindex  = read_data("docs.dat")


##  List that contain all URL                                                                                                            


ulist = []




a = docindex.values


a.each do  |b|
  ulist.push(b[2])
end



###### URL hash table
##  Hash Table for outdegree link   

outhash = Hash.new

ulist.each do |a|

  rp = retrieve_page(a)

  fl = find_links(rp)

  fl.each do |b|

   if not  ulist.include?(b)
     fl.delete(b)
   end ##end for if loop


  end ##end for fl

  outhash[a] = fl
end#end for ulist



##  HashTable for indegree link                                                                                                          

inhash = Hash.new

outvals = outhash.values
ulist.each do |b|
  outvals.each do |a|
    if a.include?(b)
      if inhash.has_key?(b)
        inhash[b].push(outhash.key(a))
        else
        inhash[b] = [outhash.key(a)]
        end
      end
    end
end



#### danglin_nodes  : pages without outgoing link

dangling_nodes = Array.new 
outhash.each do |k,v|
  if v == []
    dangling_nodes.push k
  end
end



######## pagerank  #######

rank = Hash.new
n = outhash.length  

### initialize the pagerank with 1/n
outhash.each_key do |a|
  rank[a] = 1.0 / n
end

###  computing page rank

k = 0 

p = 0.25  # damping factor (recommended value: 0.85)
thresh = 0.000001 # convergence threshold


begin 
  rank_sum = 0.0
  diff_sum = 0.0
  last_rank = rank.clone 


## danglingranks 

  danglingranks = 0.0
  dangling_nodes.each do |a|
  danglingranks += last_rank [a]
  end


## pagerank
  outhash.each_key do |a|
    inranks  = 0.0
    if  inhash[a]  != nil
      inhash[a].each do |b|
        inranks += last_rank[b]/(outhash[b].length)
        end
      end
    rank [a] = (1 - p ) * (inranks + danglingranks / n) + p / n
    rank_sum += rank [a]

    diff = last_rank[a] - rank[a]
    diff_sum += diff.abs
  end

  k += 1

end while diff_sum > thresh


### newhash pagerank   "0.html"=> pagerank score

newrank = Hash.new
docindex.each do |k,v|

  rank.each do |key,value|
    if v[2] = key
      newrank[k] = value
      end
    end
end

  



yy = write_data('pagerank.dat',newrank)







print newrank



