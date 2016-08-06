
instance_id = `curl -s "http://169.254.169.254/latest/meta-data/instance-id"`
vpc_id = `aws ec2 describe-instances --region us-west-2 --instance-ids #{instance_id} --output text --query 'Reservations[].Instances[].[VpcId]'`
vpc_id = vpc_id.gsub("\n","")

if node[:vpc_id][:dev].include?(vpc_id) then
	ses_creds = 'devAWS'
elsif node[:vpc_id][:prod].include?(vpc_id) then
	ses_creds = 'prodAWS'
else 
	p "***************************************************"
	p "************VPC DOESNOT EXIST**********************"
	p "***************************************************"
end

smtpCreds = data_bag_item('ses', ses_creds, File.read('/etc/chef/encrypted_data_bag_secret'))
smtpUserName = smtpCreds['smtpUserName']
smtpPassword = smtpCreds['smtpPassword']

include_recipe 'chef_handler'
handler_path = node['chef_handler']['handler_path']
handler = ::File.join handler_path, 'send_email'

template "#{handler}.rb" do
	source 'send_email.rb.erb'
	variables({
		:smtpUserName => smtpUserName,
		:smtpPassword => smtpPassword,
    	:ses_verified_email => node[:ses][:verified_email]
    })
end

chef_handler 'BeFrank::SendEmail' do
  source handler
  action :nothing
  supports :exception=>true
end.run_action(:enable)
