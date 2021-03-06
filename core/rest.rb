# takes care of all the rest calls
require 'net/https'
require 'uri'
require_rel './core/multipart.rb'
require_rel './core/authentication'
require_rel './core/ctxt'
class Rest
	@@count=0
	@@conn=nil
	def self.init_conn(authUri)
		if @@conn==nil
			@@conn= Net::HTTP.new(authUri.host,authUri.port)
			if authUri.scheme=="https"
				Ctxt.logger.debug("Using SSL")
				#TODO: not verifying, this may be an issue for testing 
				@@conn.use_ssl = true
			end

			@@conn.read_timeout = Ctxt.conf[Ctxt.conf.class::TIMEOUT_SECONDS].to_s.to_i
			@@conn.start()
		end
	end
	def self.get_resource(uri,time_out=nil)
		begin
			authUri = URI.parse(Authentication.prepare_authenticated_uri(uri))
			self.init_conn(authUri)
			Ctxt.logger.debug(authUri) 
			request = Net::HTTP::Get.new(authUri.request_uri)
			response=@@conn.request(request)
			case response
			when Net::HTTPSuccess
				return response.body
			else
				Ctxt.logger.debug("error from WS: #{response.body}")
				return RestError.new(response,response.body)
			end
		rescue Exception=>e
			if e.to_s=='wrong status line: "\025\003\001\000\002\002"'
				raise RuntimeError,"Looks like the WS is expecting a SSL connection" 
			else
				return nil
			end
		end
		##response = Net::HTTP.get_response(authUri)
		#puts "Response was #{response}"

	end


	# TODO make this more WS-agnostic (factor out post field names)
	def self.post_resource(uri, request_contents, data)
		begin
			authUri = URI.parse(Authentication.prepare_authenticated_uri(uri))
			self.init_conn(authUri)
			request = Net::HTTP::Post.new(authUri.request_uri)
			Ctxt.logger.debug("Request data #{request_contents}")
			# send the request as the body
			if data == nil
				request.body = request_contents
				Ctxt.logger.debug(request.body)	
				response = @@conn.request(request)
				# else attach the data as a file in a multipart request
			else
				params = {}
				params["job-data"] = data
				params["job-request"] = request_contents

				mp = Multipart::MultipartPost.new
				query, headers = mp.prepare_query(params)
				response = post_form(authUri, query, headers)

			end
			Ctxt.logger.debug("Response was #{response}")
			case response
				when Net::HTTPCreated
					return response.body
				else
					return RestError.new(response,response.body)
			end
		rescue Exception => e
			#puts e.backtrace	
			#puts e.message 
			raise RuntimeError,"Error: POST #{uri.to_s} failed."

		end
	end
	def self.put_resource(uri,contents)
		begin
			authUri = URI.parse(Authentication.prepare_authenticated_uri(uri))
			request = Net::HTTP::Put.new(authUri.request_uri)
			self.init_conn(authUri)	
			request.body =contents
			Ctxt.logger.debug("Putting #{request.body}")	
			response = @@conn.request(request)

			Ctxt.logger.debug("Response was #{response}")
			case response
			when Net::HTTPSuccess
				return response.body
			else
				Ctxt.logger.debug("error from WS: #{response.body}")
				return RestError.new(response,response.body)
			end
		rescue
			#puts "Error: DELETE #{uri.to_s} failed."
			return false
		end

	end


	def self.delete_resource(uri)
		begin
			authUri = URI.parse(Authentication.prepare_authenticated_uri(uri))
			request = Net::HTTP::Delete.new(authUri.request_uri)
			self.init_conn(authUri)	
			response = @@conn.request(request)

			Ctxt.logger.debug("Response was #{response}")

			case response
			when Net::HTTPNoContent
				return true
			else
				return RestError.new(response,response.body)
			end
		rescue
			#puts "Error: DELETE #{uri.to_s} failed."
			return false
		end

	end

	def self.post_form(url, query, headers)
		@@conn.read_timeout = Ctxt.conf[Ctxt.conf.class::TIMEOUT_SECONDS].to_s.to_i
		begin
			return @@conn.post(url.request_uri, query, headers)
		rescue => e
			CliWriter::ln "POST Failed #{e}... #{Time.now}"
		end
	end

end
class RestError
	attr_accessor :err,:uri,:trace,:desc
	def initialize(err,text)
		@err=err
		@uri=nil
		@trace=nil
		@desc=nil
		fromXml(text) if text!=nil 
	end

	def fromXml(str)
		begin
			doc=Document.new str
			xerr = XPath.first(doc,"//ns:error",Resource::NS)
			@uri=xerr.attributes["query"]
			@desc=XPath.first(doc,"//ns:description",Resource::NS).text
			@trace=XPath.first(doc,"//ns:trace",Resource::NS).text
		rescue
		end
	end
end
