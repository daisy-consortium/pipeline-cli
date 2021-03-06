require 'yaml'
require_rel './core/ctxt'
class Conf
	@map = nil

	CONFIG_ITEMS={   "port"=>"Port number",
		         "host"=>"Host name ",
			 "ws_path"=>"Path to the ws (as in http://host/ws_path) ",
			 "exec_line_win"=>" ",
			 "exec_line_nix"=>" ",
			 "exec_line"=>"Path to the pipeline2 script ",
			 "local"=>"CLI mode, true is local, false is remote (must be coherent with the ws instance) ",
			 "base_uri"=>"Connection uri, fromed by host:port/ws_path ",
			 "ws_timeup"=>"Time in seconds to wait for the ws to start (if in local mode) ",
			 "client_key"=>"Client key",
			 "client_secret"=>"Client secret ",
			 "authenticate"=>"If true will send the authenticated url's to the ws",
			 "timeout_seconds"=>"Connection timeout",
			 "debug"=>"If true debug messages are printed on the terminal",
			 "ws_version"=>" Daisy pipeline 2 version",
			 "null"=> " ",
			"prog_name"=>"" ,
			"short_name"=>"" ,
			"base_dir"=>"",
			"version"=>"",
                        "starting"=>"Starts the framework in if it's not up"
	
	}

			#Not configurable from args or file

	CONST_FILTER=["local","authenticate","version","null","exec_line_nix","exec_line_win","base_uri","prog_name","short_name","base_dir","ws_version"]

	def initialize(file)
		__init_constants__
		@map=YAML.load_file file
		Ctxt.logger.debug(@map)
		#HACK: the null redirects avoids win to get stuck creating the 
		update_vals
	end

	def [](key)
		return @map[key]
	end
	def []=(key,val)
		@map[key]=val
	end

	def __init_constants__
		CONFIG_ITEMS.keys.each do |cnst|
			Conf.const_set(cnst.upcase,cnst)
		end	
	end
	def update_vals
		if @map[DEBUG]==true||@map[DEBUG]=='true'

			Ctxt.logger.level=Logger::DEBUG
		else
			Ctxt.logger.level=Logger::INFO
		end

		if RUBY_PLATFORM =~ /mingw32/
			@map[EXEC_LINE]=@map[EXEC_LINE_WIN]
			@map[NULL]=" >  NUL 2>&1"
		else
			@map[EXEC_LINE]=@map[EXEC_LINE_NIX] 
			@map[NULL]=" 1> /dev/null 2>&1" 
		end
		@map[BASE_URI]= @map[HOST]+":"+@map[PORT].to_s+"/"+@map[WS_PATH]
	end

end	
	
