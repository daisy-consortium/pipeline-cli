require './core/ctxt'
require './core/scripts'
require './core/alive'
require './core/job'
require "open3"
#TODO asking if the service is alive before every call may not be a good idea, store that it's alive once and asume it in next calls
class Dp2
	def initialize
		Ctxt.logger.debug("initialising dp2 link")
		@basePath=File::dirname(__FILE__)+File::SEPARATOR+".."+File::SEPARATOR
		alive!
		
	end

	#private methods
	def alive! 
		if !alive?
		
			execPath=File::expand_path(Ctxt.conf[Ctxt.conf.class::EXEC_LINE],@basePath)
			#
			ex=IO.popen(execPath ) 

			#system('start '+execPath)
			#will throw execetion the command is not found
			pid =ex.pid
			Ctxt.logger().debug("ws launched with pid #{pid}")
			Ctxt.logger().info("wainting for the ws to come up...")
			wait_till_up	
			Ctxt.logger().info("ws up!")
		end	
		return true
	end

	def wait_till_up
		time_waiting=0
		time_to_wait=0.33
		while !alive?  && time_waiting<Ctxt.conf[Ctxt.conf.class::WS_TIMEUP]
			#Ctxt.logger.debug("going to sleep #{time_to_wait}")
			sleep time_to_wait
			time_waiting+=time_to_wait
			#Ctxt.logger.debug("time_waiting #{time_waiting}")
		end
		raise RuntimeError,"WS is not up and I have been waiting for #{time_waiting} s" if !alive?
	end
	#public methods
	def scripts
		if alive?
			return ScriptsResource.new.getResource
		end
		return nil
	end

	def job(script,data,wait)
		job=nil
		msgIdx=0
		if alive?
			id=JobResource.new.postResource(script.to_xml_request,nil)
			if wait==true
				begin
					sleep 1.5 
					job=job_status(id,msgIdx)
					job.messages.each{|msg| puts msg.to_s}
					if job.messages.size > 0
						msgIdx=job.messages[-1].seq
					end
					Ctxt.logger.debug("msg idx #{msgIdx}")	
				end while job.status=='RUNNING' 
			end 
		end
		return job
	end

	def job_status(id,msgSeq=0)
		#if alive?
			return JobStatusResource.new(id,msgSeq).getResource
		#end
		return nil

	end	
	def alive?	
  		return AliveResource.new.getResource 
	end	
	
	private :alive?,:alive!,:wait_till_up

end
