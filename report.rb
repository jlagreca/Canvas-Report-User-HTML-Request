# Edit these:
access_token = ''
domain = ''  #only need the subdomain
env = nil #test, beta or nil
filename = 'report.csv'
$usernumber = 10 #number of user pages to return
#============
# Don't edit from here down unless you know what you're doing.

require 'unirest'
require 'csv'
require 'json'
require 'open-uri'
require 'fileutils'
require "net/http"
require "active_support/all"

unless access_token
  puts "what is your access token?"
  access_token = gets.chomp
end

unless domain
  puts "what is your Canvas domain?"
  domain = gets.chomp
end


env ? env << "." : env
base_url = "https://#{domain}.#{env}instructure.com/api/v1"


#loop to meet xNumber of users 1500 Or get number of user
$i = 1
fileheaders = ["user_id", "user_name", "login_id", "ip_address", "request_page", "request_id", "context","activity", "interaction_time", "interaction_date"]
                CSV.open("#{filename}", "w") do |csv| #open new file for write
                                csv << fileheaders
                              end

until $i > $usernumber  do

  url ="#{base_url}/accounts/self/users?page=#{$i}&per_page=100"
   
#  

            allusers = Unirest.get(url, headers: { "Authorization" => "Bearer #{access_token}" }) 
           # puts allusers
            
            job = allusers.body
            #puts job
                
               
                  job.each do |requests|
                      #puts requests
                      canvas_id = requests["id"]
                      user_id = requests["sis_user_id"]
                      user_name = requests["name"]
                      login_id = requests["login_id"]
                      data = []

                  
                         $pageviewurl = "#{base_url}/users/#{canvas_id}/page_views?per_page=100"
                         #puts $pageviewurl
                          more_results = true

                          


                          while more_results do

                            # Send a GET request to the List Payments endpoint
                            #puts $pageviewurl
                            list_pageviews = Unirest.get($pageviewurl, headers: { "Authorization" => "Bearer #{access_token}" })

                            # Read the converted JSON body into the cumulative array of results
                            pageviews = list_pageviews.body

                            if list_pageviews.code == 200

                                  pageviews.each do |views|

                                  request_id = views["id"]
                                  ip_address = views["remote_ip"]
                                  request_page = views["url"]
                                  context = views["context_type"]
                                  activity = views["asset_type"]
                                  interaction_time = views["interaction_second"]
                                  interaction_date = views["created_at"]

                                  data = [user_id, user_name, login_id, ip_address, request_page, request_id, context, activity, interaction_time, interaction_date]
                                  puts data
                                 

                                        CSV.open("#{filename}", "a") do |csv| #open same file for write
                                          csv << data #write value to file
                                        end
                                
                                end

                          

                         end
                          

                              pagination_header = list_pageviews.headers[:link]
                        
                              
                              
                              if pagination_header.include? "rel=\"next\"" 

                                $pageviewurl=pagination_header.split('<')[2].split('>')[0]
                                
                                 puts "this is subsequent loops"
                                 puts $pageviewurl
                                 more_results = true

                  
                            
                              


                              else
                                more_results = false
                              end
                            
                          end
                      end


                  $i += 1;


               end



puts "Successfully output file"

