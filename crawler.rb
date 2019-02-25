# a string containing the HTML contents of the page                                                                                                                                                                                                                                                                                                   
require 'mechanize'
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
  html_code.links_with(:href => /^https?/).each do |link|
    ls.push(link.href)
  end
  ls = ls.uniq
  return ls
end



#                                                                                                                                                                                                                                                                                                                                                                 
# You'll likely need other functions. Add them here!                                                                                                                                                                                                                                                                                                              
#                                                                                                                                                                                                                                           =
def bfs_save(rp,fl,num)
  agent = Mechanize.new
  agent.read_timeout = 5
  agent.log = Logger.new "mech.log"
  #agent.user_agent_alias = 'Mac Safari'                                                                                                                                                                     
  visited = []
  start_list = fl
  ss = start_list[0]
puts "ss1"

  while visited.length < num.to_i
puts "ss2"
    if not(visited.include?(ss))
puts"ss3"
      visited.push(ss)
      begin
        page = agent.get ss
      rescue Exception=>e
        puts e
        next
      end
        begin  
          page.links_with(:href => /^https?/).each do |link|
            start_list.push(link.href)
          end
        rescue Exception=>e
          puts e
          next
        end
    else
puts visited.length
      start_list.shift()
      ss = start_list[0]
    end
  end
  return visited
end

#print eee                                                                                                                                                                                                                                                                                                                                                        
#################################################                                                                                                                                                                                                                                                                                                                 
# Main program. We expect the user to run the program like this:                                                                                                                                                                                                                                                                                                  
#                                                                                                                                                                                                                                                                                                                                                                 
#   ruby crawl.rb seed_url max_pages output_directory algorithm                                                                                                                                                                                                                                                                                                   
#                                                                                                                                                                                                                                                                                                                                                                 

# check that the user gave us 4 command line parameters                                                                                                                                                                                                                                                                                                           

if ARGV.size != 4
  abort "Command line should have 4 parameters."
end


# fetch command line parameters                                                                                                                                                                                                                                                                                                                                   
(seed_url, max_pages, output_dir, algorithm) = ARGV

# add main body of program here!                                                                                                                                                                                                                                                                                                                                  
pages_content = retrieve_page(seed_url)


rp = retrieve_page(seed_url)

fl = find_links(rp)

#sss = dfs_save(rp,fl,max_pages)

eee = bfs_save(rp,fl,max_pages)

if algorithm == 'bfs'
  for x in eee
    agent = Mechanize.new
    agent.log = Logger.new "mech.log"
    begin
    mon = agent.get x
    rescue Exception=>e
    puts e
    next
    end
    mon.save_as output_dir + eee.index(x).to_s + '.html'
    sleep 1
    outfile = File.new('index.dat','a')
    outfile.puts eee.index(x).to_s + '.html ' + x.to_s
    outfile.close
  end
end
