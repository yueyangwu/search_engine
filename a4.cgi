#!/l/ruby-2.2.2/bin/ruby                                                        

require 'cgi'
require 'mechanize'
require 'fast_stemmer'
#require 'iconv'



cgi = CGI.new("html4")

query = cgi['input'].to_s
#query = query.downcase
query = query.split(" ")
#ARGV =query


time = Time.new.asctime




def find_tokens(url)
  word_list = " "
  rr = Nokogiri::HTML(url)
  words = rr.text.split(/[ ,\-,\n,\r,\t,&]/)
  words.each {|w|
    word_list+=w
    word_list+=" "
  }
  #word_list.reject!{|c| c.empty?}                                                                                                                       
  return word_list
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
  object =eval(file.gets.untaint.encode('UTF-8', :invalid => :replace))
  file.close()
  return object
end



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


# count tf-idf score  tf-idf socre = tfscore * idfscore                                         
# tfscore = how many times term in this html file / total words of this html file               
# dfscore = how many document contain this term                                                 
# idfscore = 1/ (1 + log (dfsocre))                                                             
# totalsocre is add each term in query tf-idf score together                                    
def tdscore(query,invindex,docindex,docname)
  tfscore = 0
  dfscore = 0
  idfscore = 0
  tf_dfscore = 0
  totalscore = 0

  query.each do |term|
    dfscore =  invindex[term][0]
    idfscore = 1/(1+Math.log(dfscore))
    tfscore = (invindex[term][1][docname]).to_f/(docindex[docname][0]).to_f
    tf_dfscore = tfscore * idfscore
    totalscore = (totalscore + tf_dfscore)
  end
  return totalscore
end


def find_hitlist(mode, query, invindex)
  hit_list = Array.new
  hit_hash = Hash.new 0
  temp_list = Array.new

  first = 0

  query.each do |term|
    #puts term                                                                                  
    if invindex.has_key?(term)
      #puts invindex[term][1].keys.inspect                                                      
      if (first == 0)
        hit_list |= invindex[term][1].keys
        hit_list.each {|doc| hit_hash[doc] += 1}
        first = 1
      else
       # if (mode == "or")                                                                      
        #  hit_list |= invindex[term][1].keys                                                   
       # elsif (mode == "and")                                                                  
        #  hit_list &= invindex[term][1].keys                                                   
        if (mode == "most")
          temp_list = invindex[term][1].keys
          temp_list.each {|doc| hit_hash[doc] += 1}
          #puts temp_list.inspect                                                               
        end
      end
    else
      hit_list = []
    end
  end


  if (mode == "most")
    #initizlie hit_list                                                                         
    hit_list = []
    hit_hash.each {|k, v| hit_list.push(k) if v > (query.length / 2)}
  end

  return hit_list
end



mode = "most"


# read in the index file produced by the crawler from Assignment 2 (mapping URLs to filenames).
docindex=read_data("docs.dat")

# read in the inverted index produced by the indexer.                                           
invindex=read_data("invindex.dat")

# read in the pagerank score 

pagerank=read_data("pagerank.dat")

# read in list of stopwords from file                                                           
stopwords = load_stopwords_file("stop.txt")


#puts keyword_list.inspect                                                                      

# Step (1) Stem and stop the query terms                                                        
query_term = stem_tokens(query)
#puts query_term.inspect                                                                        

clean_query = remove_stop_tokens(query_term, stopwords)
#puts clean_query.inspect                                                                       

# Step (2) Use the inverted index file to find the hit list                                     
hit_list = find_hitlist(mode, clean_query, invindex)
#puts hit_list.inspect                                                                          
#                                                                                               
#                                                                                               
# Step (3) For each page in the hit list,                                                       
# display the URL and the title of the HTML page                                                
num_of_doc = hit_list.length


#sort hit list using TF-IDF score                                                               

score_hash = Hash.new
#calculate html tf-idf score in hit_list and map them into a hash                               
hit_list.each do |page|
  score = tdscore(clean_query,invindex,docindex,page)
  score_hash[page] = score
end


###hash combine tf-idf score and pagerank score. 
## proportion is hashtable 4 : pagerank 1

final_hash = Hash.new

score_hash.each do |k,v|
  final_hash[k] = v * 4 + pagerank[k]

end


#sorted hash key by hash value [but we will get a list that contain many list, each of them contain html name and score of it]                                                                 

new_hash = final_hash.sort_by{|k,v| v}

#new_list is a list of html but sorted by combine score. the beginning one has largest score.    
new_list = []

new_hash.each do |a|
  new_list.unshift(a[0])
end

final_list = new_list[0..24]



html = ""


final_list.each do |page|
  page_title = docindex[page][1]
  page_url = docindex[page][2]
  page_content = find_tokens(page_url)
  finalscore = score_hash[page]
 if not finalscore.to_s == "Infinity"
   