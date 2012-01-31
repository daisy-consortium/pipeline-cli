require_rel './core/resource'
class JobResource < Resource
	def initialize
		super("/jobs",{},JobPostResultProcessor.new)
	end	
end

class DeleteJobResource < Resource
	def initialize(id)
		super("/jobs",{:id=>id},DeleteJobResultProcessor.new)
	end	
	def buildUri
    		uri = "#{Ctxt.conf[Ctxt.conf.class::BASE_URI]}#{@path}/#{@params[:id]}"
		Ctxt.logger.debug("URI:"+uri)
		uri
	end
end
class JobsStatusResource < Resource
	def initialize
		super("/jobs",{},JobsStatusResultProcessor.new)
	end	
end
class JobResultZipResource < Resource
	def initialize(id,output_path)
		super("/jobs",{:id=>id},JobZipResultProcessor.new(output_path))
	end	
	def buildUri
    		uri = "#{Ctxt.conf[Ctxt.conf.class::BASE_URI]}#{@path}/#{@params[:id]}/result"
		Ctxt.logger.debug("URI:"+uri)
		uri
	end
end
class JobStatusResource < Resource
	def initialize(id,seq=0)
		super("/jobs",{:id=>id,:seq=>seq},JobStatusResultProcessor.new)
	end
	def buildUri
    		uri = "#{Ctxt.conf[Ctxt.conf.class::BASE_URI]}#{@path}/#{@params[:id]}?msgSeq=#{@params[:seq]}"
		Ctxt.logger.debug("URI:"+uri)
		uri
	end
			
end

class JobStatusResultProcessor < ResultProcessor
	def process(input)
		raise RuntimeError,"Empty result from WS" if input==nil
		#return Job.new if input==nil

		doc=Nokogiri.XML(input)
		
		doc.remove_namespaces!
		xjob=doc.at_xpath("//job")
		job=Job.fromXml(xjob)
		Ctxt.logger.debug(job.to_s)
		return  job
	end
end

class JobZipResultProcessor < ResultProcessor
	def initialize(path)
		@path=path	
	end
	def process(input)
		f=File.open(@path, 'wb')
		f.write(input)
		f.close
		return @path
	end
end
class JobsStatusResultProcessor < ResultProcessor
	def process(input)
		raise RuntimeError,"Empty job result from server " if input==nil
		doc=Nokogiri.XML(input)
		
		doc.remove_namespaces!
		xjobs=doc.xpath("//job")
		jobs=[]
		xjobs.each { |xjob|
			jobs.push(Job.fromXml(xjob))
		}
		Ctxt.logger.debug(" Jobs retrieved #{jobs.size}")
		return  jobs
	end
end
class JobPostResultProcessor < ResultProcessor
	def process(input)
		raise RuntimeError,"Empty result from WS" if input==nil
		#return Job.new if input==nil

		doc=Nokogiri.XML(input)
		
		doc.remove_namespaces!
		xjob=doc.at_xpath("//job")
		job=Job.fromXml(xjob)
		Ctxt.logger.debug(job.to_s)
		puts "[DP2] Job with id #{job.id} submitted to the server"
		return job 
	end
end
class DeleteJobResultProcessor < ResultProcessor
	def process(bool)
		return bool
	end
end
class Message
	attr_accessor :msg,:level,:seq
	def to_s
			return "#{@level}(#{@seq}) - #{@msg[0..150]}"
	end
end
class Job

	attr_accessor :id,:status,:script,:result,:messages,:log
	def initialize(id)	
		@id=id
		@messages=[]
	end
	def self.fromXml(element)
		Ctxt.logger.debug("from element: #{element.to_s}")
		job=Job.new(element.attr("id"))
		job.status=element.attr("status")
	
		xscript=element.at_xpath("./script")
		xresult=element.at_xpath("./result")
		xlog=element.at_xpath("./log")
		xmessages=element.xpath("./messages/message")
		xmessages.each{|xmsg|
			msg= Message.new 
			msg.msg=xmsg.content
			msg.level=xmsg.attr("level")
			msg.seq=xmsg.attr("sequence")
			job.messages.push(msg)		
		}
		job.script=Script.fromXmlElement(xscript) if xscript!=nil
		job.result=xresult.attr("href") if xresult!=nil
		job.log=xlog.attr("href") if xlog!=nil
	
		return job
	end

	def to_s
		s="Job Id: #{@id}\n"
		s+="\t Status: #{@status}\n"
		s+="\t Script: #{@script.uri}\n" if @script!=nil
		s+="\t Result: #{@result}\n" if @result!=nil
		s+="\t Log: #{@log}\n" if @log!=nil
		s+="\t Messages: #{@messages.size}\n"
		s+="\n"
		return s	
	end	

end