##
## getting_started.rb - This script will take a chef_server_url, username, password and org
##
## John Cook, jcook@fastrobot.com

require 'fileutils'
require 'openssl'
require 'nokogiri'
require 'httpclient'

args = ARGV
abort('Error parsing arguments: Must be in order <chef_server_url> <org> <username> <password>') if args.length < 4
chef_server_url = args[0] #'https://ec2-52-9-121-235.us-west-1.compute.amazonaws.com'
org = args[1]             #'testorg'
username = args[2]        #'chefuser'
password = args[3]        #'chefpass'
instance_id = args[4]     #Instance_id of the Chef-Server to use

##
# Create client set SSL config to FALSE
client = HTTPClient.new
client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
# Now create the cookie jar and tell the client to use it
FileUtils.touch('/tmp/cookie.dat')
client.set_cookie_store('/tmp/cookie.dat')

#
## Are we running a marketplace ami?  Post the instacne_id
unless instance_id.to_s == ''
  homepage = Nokogiri::HTML(client.get_content(chef_server_url))
  data = [['uuid',instance_id]]
  client.post("#{chef_server_url}/biscotti",data)
end

##
# Grab chef_server_url login page to parse csrf-tokens
login = Nokogiri::HTML(client.get_content("#{chef_server_url}/login"))

csrf_token = String.new
login.xpath('//head/meta').each do |m|
  csrf_token = m.values[1] if m.values[0] == 'csrf-token'
end

form_tokens = Array.new
login.xpath('//form/input').each do |i|
  form_tokens << i['value'] if i['name'] == 'authenticity_token'
end

##
## Build post request to login to our new Chef-Server
extheaders = {'X-CSRFToken' => csrf_token}
data = [['utf8','%E2%9C%93']]
form_tokens.each do |ft|
  data << ['authenticity_token', "#{URI.encode(ft)}"]
end
data << ['to','']
data << ['username',username]
data << ['password',password]
data << ['commit','Sign In']

print 'Attempting to post credentials to Chef Server...'
res = client.post("#{chef_server_url}/login",data,extheaders)

if Nokogiri::HTML(res.content).xpath('//html/body').text != 'You are being redirected.'
  puts "FAILED."
  abort("Verify your login credentials with the Chef-Server (#{chef_server_url}/login)")
end

puts "SUCCESS!"

##
## Grab csrf tokens for the getting_started page
gs = Nokogiri::HTML(client.get_content("#{chef_server_url}/organizations/#{org}/getting_started"))
csrf_token = String.new
gs.xpath('//head/meta').each do |m|
  csrf_token = m.values[1] if m.values[0] == 'csrf-token'
end

##
## Build post to download the chef-starter.zip file
data = [['authenticity_token',"#{URI.encode(csrf_token)}"]]

kit = client.post_content("#{chef_server_url}/organizations/#{org}/getting_started",data)

starter_kit = File.new('chef-starter.zip', 'wb')
starter_kit.write(kit)
