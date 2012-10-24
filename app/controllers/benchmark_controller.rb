require 'helper'
class BenchmarkController < ApplicationController
  include Helper
  
  def generate
    
    @status = ""
    
    logger.debug "----------------------------------"    
    logger.debug "::: Taking values from the form..."
    logger.debug "----------------------------------"
    @status << "-------------------------------\n"
    @status << "<strong>::: Taking values from the form</strong>\n"
    @status << "-------------------------------\n"
    
    # get values from the view
    # and generate multiple profiles
    #
    # layer 1: instance type [small/medium/large]
    # layer 2: java heap size [low/high]
    # layer 3.1: key cache size [small/medium/high]
    # layer 3.2: row cache size [small/medium/high]
    #
    # each layer is represented as an array    
    instance_type_array = []
    java_heap_size_array = []
    key_cache_size_array = []
    row_cache_size_array = []
    
    # layer 1:
    # instance type array
    # 0 --> medium
    # 1 --> large
    # using ternary operator, maybe for a better coding and reading hehe
    # syntax: condition ? then_branch : else_branch 
    logger.debug "::: Selected Instance Types:"
    @status << "<strong>::: Selected Instance Types:</strong>\n"
         
    ! params[:instance_medium].nil? ? instance_type_array[0] = 1 : instance_type_array[0] = 0
    if instance_type_array[0] == 1 
      logger.debug "Medium" 
      @status << "Medium\n"
    end
      
    ! params[:instance_large].nil? ? instance_type_array[1] = 1 : instance_type_array[1] = 0      
    if instance_type_array[1] == 1 
      logger.debug "Large" 
      @status << "Large\n"  
    end

    # layer 2:
    # java heap size
    # 0 --> low
    # 1 --> high
    logger.debug "::: Selected Java Heap Sizes:"
    @status << "<strong>::: Selected Java Heap Sizes:</strong>\n"
    
    ! params[:heap_low].nil? ? java_heap_size_array[0] = 1 : java_heap_size_array[0] = 0
    if java_heap_size_array[0] == 1 
      logger.debug "Low" 
      @status << "Low\n"  
    end
      
    ! params[:heap_high].nil? ? java_heap_size_array[1] = 1 : java_heap_size_array[1] = 0
    if java_heap_size_array[1] == 1 
      logger.debug "High" 
      @status << "High\n"  
    end


    # layer 3.1:
    # key cache size
    # 0 --> low
    # 1 --> medium
    # 2 --> high
    logger.debug "::: Selected Key Cache Sizes:"
    @status << "<strong>::: Selected Key Cache Sizes:</strong>\n"
    
    ! params[:key_cache_low].nil? ? key_cache_size_array[0] = 1 : key_cache_size_array[0] = 0
    if key_cache_size_array[0] == 1 
      logger.debug "Low" 
      @status << "Low\n"  
    end
      
    ! params[:key_cache_medium].nil? ? key_cache_size_array[1] = 1 : key_cache_size_array[1] = 0
    if key_cache_size_array[1] == 1 
      logger.debug "Medium" 
      @status << "Medium\n"
    end

    ! params[:key_cache_high].nil? ? key_cache_size_array[2] = 1 : key_cache_size_array[2] = 0
    if key_cache_size_array[2] == 1 
      logger.debug "High" 
      @status << "High\n"  
    end
    
    # layer 3.2:
    # row cache size
    # 0 --> low
    # 1 --> medium
    # 2 --> high
    logger.debug "::: Selected Row Cache Sizes:"
    @status << "<strong>::: Selected Row Cache Sizes:</strong>\n"
    
    ! params[:row_cache_low].nil? ? row_cache_size_array[0] = 1 : row_cache_size_array[0] = 0
    if row_cache_size_array[0] == 1 
      logger.debug "Low" 
      @status << "Low\n"
    end
      
    ! params[:row_cache_medium].nil? ? row_cache_size_array[1] = 1 : row_cache_size_array[1] = 0
    if row_cache_size_array[1] == 1 
      logger.debug "Medium" 
      @status << "Medium\n"
    end

    ! params[:row_cache_high].nil? ? row_cache_size_array[2] = 1 : row_cache_size_array[2] = 0
    if row_cache_size_array[2] == 1 
      logger.debug "High" 
      @status << "High\n"
    end

    # test
    puts "Key Cache Size Array:"
    puts key_cache_size_array
    
    puts "Row Cache Size Array:"
    puts row_cache_size_array

    logger.debug "--------------------"
    logger.debug "::: Checking Input..."
    logger.debug "--------------------"
    @status << "------------------\n"
    @status << "<strong>::: Checking Input</strong>\n"
    @status << "------------------\n"
    if ! instance_type_array.include? 1
      logger.debug "Input [NOT OK]"
      @status << "Input <strong>[NOT OK]</strong>"
      logger.debug "You have to choose at least an instance type!"
      @status << "You have to choose at least an <strong>instance type!</strong>\n"
    elsif ! java_heap_size_array.include? 1
      logger.debug "Input [NOT OK]"
      @status << "Input <strong>[NOT OK]</strong>"
      logger.debug "You have to choose at least a Java heap size!"
      @status << "You have to choose at least a <strong>Java heap size!</strong>\n"
    elsif (! key_cache_size_array.include? 1) && (! row_cache_size_array.include? 1)
      logger.debug "Input [NOT OK]"
      @status << "Input <strong>[NOT OK]</strong>"
      logger.debug "You have to choose at least a Key Cache size OR a Row Cache size!"
      @status << "You have to choose at least a <strong>Key Cache size</strong> OR a <strong>Row Cache size</strong>\n"
    else
      logger.debug "Input [OK]"
      @status << "Input <strong>[OK]</strong>\n"
      
      logger.debug "------------------------------------------------------------------------------"
      logger.debug "::: Creating a bucket called 'kcsdb-profiles' for all profiles in S3 if needed"
      logger.debug "------------------------------------------------------------------------------"
      s3 = create_fog_object 'aws', nil, 'storage'
      
      # check if a bucket called 'kcsdb-profiles' already exists
      dirs = s3.directories
      check = false
      dirs.each {|dir| if dir.key == "kcsdb-profiles" then check = true end}
      
      # if this bucket does not exist than create a new one
      kcsdb_profiles = nil
      if ! check
        logger.debug "Bucket 'kcsdb-profiles' does NOT exist, create a new one..."
        kcsdb_profiles = s3.directories.create(
          :key => "kcsdb-profiles",
          :public => true
        )
      else
        logger.debug "Bucket 'kcsdb-profiles' EXIST, get the bucket..."
        kcsdb_profiles = s3.directories.get 'kcsdb-profiles'
      end        
      
      logger.debug "--------------------------------"
      logger.debug "::: Generating Profile Matrix..."
      logger.debug "--------------------------------"
      
      profile_matrix_for_key_cache = []
      profile_matrix_for_row_cache = []
      
      for i in 0..(instance_type_array.size - 1)
        if instance_type_array[i] != 0
          for j in 0..(java_heap_size_array.size - 1)
            if java_heap_size_array[j] != 0
              
              if key_cache_size_array.size > 0
                for k in 0..(key_cache_size_array.size - 1)
                  if key_cache_size_array[k] != 0
                    profile_matrix_for_key_cache << i.to_s + "-" + j.to_s + "-" + k.to_s
                  end
                end
              end
              
              if row_cache_size_array.size > 0
                for l in 0..(row_cache_size_array.size - 1)
                  if row_cache_size_array[l] != 0
                    profile_matrix_for_row_cache << i.to_s + "-" + j.to_s + "-" + l.to_s
                  end
                end
              end

            end
          end  
        end
      end
      
      # test
      puts "Profile Matrix for Key Cache"
      puts profile_matrix_for_key_cache
      
      puts "Profile Matrix for Row Cache"
      puts profile_matrix_for_row_cache
      
      profile_counter = 1
      
      if profile_matrix_for_key_cache.size > 0
        logger.debug "--------------------------------------"
        logger.debug "::: Profiles for Key Cache Experiment"
        logger.debug "--------------------------------------"
        @status << "-------------------------------------\n"
        @status << "<strong>::: Profiles for Key Cache Experiment</strong>\n"
        @status << "-------------------------------------\n"
        
        profile_matrix_for_key_cache.each do |p|
          puts "Profile: #{p}"
          
          logger.debug "Profile #{profile_counter}:"
          @status << "<strong>Profile #{profile_counter}:</strong>\n"
          
          tmp_arr = p.to_s.split("-")
          
          tmpl_file = File.read "#{Rails.root}/key_cache_exp_profile_tmpl.yaml"
          profile_name = ""
          
          # check instance type: MEDIUM
          if tmp_arr[0] == 0.to_s
            logger.debug "Instance Type: Medium"
            @status << "Instance Type: Medium\n"
            profile_name << "ins.med-"
            tmpl_file.gsub!(/machine_type: dummy/, "machine_type: medium")
            # check java heap size: LOW
            if tmp_arr[1] == 0.to_s
              logger.debug "Java Heap Size: Low"
              @status << "Java Heap Size: Low\n"
              profile_name << "heap.low-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: dummy") # don't change
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: dummy") # don't change
              # check key cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "Key Cache Size: Low"
                @status << "Key Cache Size: Low\n"
                profile_name << "key.low.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: ") # don't change
              # check key cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "Key Cache Size: Medium"
                @status << "Key Cache Size: Medium\n"
                profile_name << "key.med.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 102")
              # check key cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "Key Cache Size: High"
                @status << "Key Cache Size: High\n"
                profile_name << "key.high.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 204")
              end
            # check java heap size: HIGH  
            elsif tmp_arr[1] == 1.to_s
              logger.debug "Java Heap Size: High"
              @status << "Java Heap Size: High\n"
              profile_name << "heap.high-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: 1536")
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: 100")
              # check key cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "Key Cache Size: Low"
                @status << "Key Cache Size: Low\n"
                profile_name << "key.low.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: ") # don't change
              # check key cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "Key Cache Size: Medium"
                @status << "Key Cache Size: Medium\n"
                profile_name << "key.med.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 154")
              # check key cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "Key Cache Size: High"
                @status << "Key Cache Size: High\n"
                profile_name << "key.high.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 307")
              end
            end
          # check instance type: LARGE
          elsif tmp_arr[0] == 1.to_s
            logger.debug "Instance Type: Large"
            @status << "Instance Type: Large\n"
            profile_name << "ins.lar-"
            tmpl_file.gsub!(/machine_type: dummy/, "machine_type: large")
            # check java heap size: LOW
            if tmp_arr[1] == 0.to_s
              logger.debug "Java Heap Size: Low"
              @status << "Java Heap Size: Low\n"
              profile_name << "heap.low-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: dummy") # don't change
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: dummy") # don't change
              # check key cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "Key Cache Size: Low"
                @status << "Key Cache Size: Low\n"
                profile_name << "key.low.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: ") # don't change
              # check key cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "Key Cache Size: Medium"
                @status << "Key Cache Size: Medium\n"
                profile_name << "key.med.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 186")
              # check key cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "Key Cache Size: High"
                @status << "Key Cache Size: High\n"
                profile_name << "key.high.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 372")
              end
            # check java heap size: HIGH  
            elsif tmp_arr[1] == 1.to_s
              logger.debug "Java Heap Size: High"
              @status << "Java Heap Size: High\n"
              profile_name << "heap.high-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: 2793")
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: 200")
              # check key cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "Key Cache Size: Low"
                @status << "Key Cache Size: Low\n"
                profile_name << "key.low.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: ") # don't change
              # check key cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "Key Cache Size: Medium"
                @status << "Key Cache Size: Medium\n"
                profile_name << "key.med.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 279")
              # check key cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "Key Cache Size: High"
                @status << "Key Cache Size: High\n"
                profile_name << "key.high.yaml"
                tmpl_file.gsub!(/key_cache_size_in_mb: dummy/, "key_cache_size_in_mb: 558")
              end
            end
          end
          
          logger.debug "Writting profile: #{profile_counter} in localhost..."
          File.open("#{Rails.root}/#{profile_name}",'w') {|f| f.write tmpl_file}

          logger.debug "Uploading profile: #{profile_counter} to S3..."
          file = kcsdb_profiles.files.create(
            :key    => profile_name,
            :body   => File.open("#{Rails.root}/#{profile_name}"),
            :public => true
          )          
          
          profile_counter += 1
           
        end
      end
      
      if profile_matrix_for_row_cache.size > 0
        logger.debug "--------------------------------------"
        logger.debug "::: Profiles for row Cache Experiment"
        logger.debug "--------------------------------------"
        @status << "-------------------------------------\n"
        @status << "<strong>::: Profiles for row Cache Experiment</strong>\n"
        @status << "-------------------------------------\n"
        
        profile_matrix_for_row_cache.each do |p|
          puts "Profile: #{p}"
          
          logger.debug "Profile #{profile_counter}:"
          @status << "<strong>Profile #{profile_counter}:</strong>\n"
          
          tmp_arr = p.to_s.split("-")
          
          tmpl_file = File.read "#{Rails.root}/row_cache_exp_profile_tmpl.yaml"
          profile_name = ""
          
          # check instance type: MEDIUM
          if tmp_arr[0] == 0.to_s
            logger.debug "Instance Type: Medium"
            @status << "Instance Type: Medium\n"
            profile_name << "ins.med-"
            tmpl_file.gsub!(/machine_type: dummy/, "machine_type: medium")
            # check java heap size: LOW
            if tmp_arr[1] == 0.to_s
              logger.debug "Java Heap Size: Low"
              @status << "Java Heap Size: Low\n"
              profile_name << "heap.low-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: dummy") # don't change
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: dummy") # don't change
              # check row cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "row Cache Size: Low"
                @status << "row Cache Size: Low\n"
                profile_name << "row.low.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 0") # don't change
              # check row cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "row Cache Size: Medium"
                @status << "row Cache Size: Medium\n"
                profile_name << "row.med.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 102")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache
              # check row cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "row Cache Size: High"
                @status << "row Cache Size: High\n"
                profile_name << "row.high.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 204")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache
              end
            # check java heap size: HIGH  
            elsif tmp_arr[1] == 1.to_s
              logger.debug "Java Heap Size: High"
              @status << "Java Heap Size: High\n"
              profile_name << "heap.high-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: 1536")
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: 100")
              # check row cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "row Cache Size: Low"
                @status << "row Cache Size: Low\n"
                profile_name << "row.low.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 0") # don't change
              # check row cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "row Cache Size: Medium"
                @status << "row Cache Size: Medium\n"
                profile_name << "row.med.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 154")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache
              # check row cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "row Cache Size: High"
                @status << "row Cache Size: High\n"
                profile_name << "row.high.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 307")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache             
              end
            end
          # check instance type: LARGE
          elsif tmp_arr[0] == 1.to_s
            logger.debug "Instance Type: Large"
            @status << "Instance Type: Large\n"
            profile_name << "ins.lar-"
            tmpl_file.gsub!(/machine_type: dummy/, "machine_type: large")
            # check java heap size: LOW
            if tmp_arr[1] == 0.to_s
              logger.debug "Java Heap Size: Low"
              @status << "Java Heap Size: Low\n"
              profile_name << "heap.low-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: dummy") # don't change
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: dummy") # don't change
              # check row cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "row Cache Size: Low"
                @status << "row Cache Size: Low\n"
                profile_name << "row.low.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 0") # don't change
              # check row cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "row Cache Size: Medium"
                @status << "row Cache Size: Medium\n"
                profile_name << "row.med.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 186")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache                
              # check row cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "row Cache Size: High"
                @status << "row Cache Size: High\n"
                profile_name << "row.high.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 372")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache                
              end
            # check java heap size: HIGH  
            elsif tmp_arr[1] == 1.to_s
              logger.debug "Java Heap Size: High"
              @status << "Java Heap Size: High\n"
              profile_name << "heap.high-"
              tmpl_file.gsub!(/heap_size: dummy/, "heap_size: 2793")
              tmpl_file.gsub!(/heap_new_size: dummy/, "heap_new_size: 200")
              # check row cache size: LOW
              if tmp_arr[2] == 0.to_s
                logger.debug "row Cache Size: Low"
                @status << "row Cache Size: Low\n"
                profile_name << "row.low.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 0") # don't change
              # check row cache size: MEDIUM
              elsif tmp_arr[2] == 1.to_s
                logger.debug "row Cache Size: Medium"
                @status << "row Cache Size: Medium\n"
                profile_name << "row.med.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 279")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache                
              # check row cache size: HIGH
              elsif tmp_arr[2] == 2.to_s
                logger.debug "row Cache Size: High"
                @status << "row Cache Size: High\n"
                profile_name << "row.high.yaml"
                tmpl_file.gsub!(/row_cache_size_in_mb: dummy/, "row_cache_size_in_mb: 558")
                tmpl_file.gsub!(/row_cache_save_period:.*/, "row_cache_save_period: 14400") # active row cache                
              end
            end
          end
          
          logger.debug "Writting profile: #{profile_counter} in localhost..."
          File.open("#{Rails.root}/#{profile_name}",'w') {|f| f.write tmpl_file}

          logger.debug "Uploading profile: #{profile_counter} to S3..."
          file = kcsdb_profiles.files.create(
            :key    => profile_name,
            :body   => File.open("#{Rails.root}/#{profile_name}"),
            :public => true
          )          
          
          profile_counter += 1
           
        end
      end
    
    end # end of checking input
    
  end # end of generate action
  
  
  
  
  
  
  def run
    
    get_values_from_mbean_over_jmx
    
    puts 'break point'
    exit 1
    
    # get the url for benchmark profile, given by the user
    benchmark_profile_url = params[:benchmark_profile_url]
    
    logger.debug "***************************************************************"
    
    logger.debug "---------------------------------------------------------------"
    logger.debug "::: Downloading the benchmark profile from the given source:..."
    logger.debug "::: #{benchmark_profile_url}"
    logger.debug "---------------------------------------------------------------"
    benchmark_profile_path = "#{Rails.root}/chef-repo/.chef/tmp/benchmark_profiles.yaml"
    system "curl --location #{benchmark_profile_url} --output #{benchmark_profile_path} --silent"
    
    logger.debug "------------------------------------"
    logger.debug "::: Parsing the benchmark profile..."
    logger.debug "------------------------------------"
    benchmark_profiles = Psych.load(File.open benchmark_profile_path)
    
    # contain all keys of benchmark profiles
    # the keys are split in 2 groups
    # service key: service1, service2, etc...
    # profile key: profile1, profile2, etc...
    key_array = benchmark_profiles.keys
    logger.debug "------"
    logger.debug " Keys:"
    logger.debug "------"
    puts key_array
    
    # contain service1, service2, etc..
    # each service is a hash map, e.g. name => cassandra, attribute => { replication_factor => 3, partitioner => RandomPartitioner }
    @service_array = []
    
    # contain profile1, profile2
    # each profile is a hash map, e.g. provider => aws, regions => { region1 => { name => us-east-1, machine_type => small, template => 3 service1+service2} }
    profile_array = []
    
    key_array.each do |key|
      if key.to_s.include? "service"
        @service_array << benchmark_profiles[key]
      elsif key.to_s.include? "profile"
        profile_array << benchmark_profiles[key]
      else
        logger.debug "::: Profile is NOT conform. Please see the sample to write a good benchmark profile"
        exit 0
      end
    end
    
    logger.debug "----------"
    logger.debug " Services:"
    logger.debug "----------"
    puts @service_array
    
    logger.debug "----------"
    logger.debug " Profiles:"
    logger.debug "----------"
    puts profile_array

    logger.debug "***************************************************************"

    logger.debug "-----------------------"
    logger.debug "::: RUNNING PROFILES..."
    logger.debug "-----------------------"

    profile_counter = 1
    profile_array.each do |profile| # each profile is a hash
      
      # --- profile ---
      # provider: aws
      # regions:
      #   region1:
      #     name: us-east-1
      #     machine_type: small
      #     template: 3 cassandra+gmond, 2 ycsb
      #   region2:
      #     name: us-west-1
      #     machine_type: small
      #     template: 5 cassandra+gmond, 4 ycsb
      # ...     
      logger.debug "-------------------------------------"
      logger.debug "::: RUNNING PROFILE: #{profile_counter}..."
      logger.debug "::: The profile we'are running now..."
      logger.debug "-------------------------------------"
      puts profile
      
      @db_regions = Hash.new 
      # shared variable, used to contain all IPs in each region
      # relevant information for DATABASE NODES and GMOND AGENTS which are installed in these nodes 
      # --- @db_regions ---
      # region1:
      #   name: us-east-1
      #   ips: [1,2,3]
      #   seeds: 1,2,4
      #   tokens: [0,121212,352345]
      # region2:
      #   name: us-west-1
      #   ips: [4,5]
      #   seeds: 1,2,4
      #   tokens: [4545, 32412341234]
      # attributes:
      #   replication_factor: 2,2
      
      @bench_regions = Hash.new
      # shared variable, used to contain all IPs in each region
      # relevant information for BENCHMARK NODES and GMOND AGENTS which are installed in these nodes
      # ---@bench_regions ---
      # region1:
      #   name: us-east-1
      #   ips: [1,2,3]
      # region2:
      #   name: us-west-1
      #   ips: [4,5]
      # attributes:
      #   workload_model: hotspot
      
      # temporary shared variable to store IPs of Database nodes or Benchmark nodes in each region
      # used by concurrent threads
      @db_nodes_us_east_1 = []
      @db_nodes_us_west_1 = []
      @db_nodes_us_west_2 = []
      @db_nodes_eu_west_1 = []
      @bench_nodes_us_east_1 = []
      @bench_nodes_us_west_1 = []
      @bench_nodes_us_west_2 = []
      @bench_nodes_eu_west_1 = []
      
      # lock for shared temporary varibales
      @mutex = Mutex.new
      
      # Service Provision has to be called at first
      # to provision machines in cloud infrastructure
      # profile hash is used to fill @db_regions hash
      logger.debug "----------------------------------------------------------------------------------"
      logger.debug "STEP 1: Invoking Service [Provision] for Database Cluster and Benchmark Cluster..."
      logger.debug "----------------------------------------------------------------------------------"
      start_time = Time.now
      if profile['regions']['region1']['template'].to_s.include? "cassandra" or profile['regions']['region1']['template'].to_s.include? "mongodb"
        service 'provision', profile 
      else
        logger.debug "Database Service Cassandra OR MongoDB, just one of these!"
        exit 0
      end
      logger.debug "------------------------------------------------------------------------------"
      logger.debug "---> Elapsed time for Service [Provision]: #{Time.now - start_time} seconds..."
      logger.debug "------------------------------------------------------------------------------"

      # --- @db_regions ---
      #   region1:
      #     name: us-east-1
      #     ips: [1,2,3]
      #   region2:
      #     name: us-west-1
      #     ips: [4,5]
      #....
      logger.debug "----------------------------------"
      logger.debug "::: Node IPs for Database Cluster:"
      logger.debug "----------------------------------"    
      @db_regions.each do |key,values|
        logger.debug "Region: #{values['name']}"
        logger.debug "IPs: #{values['ips']}"       
      end
      
      # --- @bench_regions ---
      #   region1:
      #     name: us-east-1
      #     ips: [1,2,3]
      #   region2:
      #     name: us-west-1
      #     ips: [4,5]
      #....
      logger.debug "-----------------------------------"
      logger.debug "::: Node IPs for Benchmark Cluster:"
      logger.debug "-----------------------------------"    
      @bench_regions.each do |key,values|
        logger.debug "Region: #{values['name']}"
        logger.debug "IPs: #{values['ips']}"       
      end
      
      logger.debug "-----------------------------------------------------------"
      logger.debug "STEP 2: Invoking Service [Database] for Database Cluster..."
      logger.debug "-----------------------------------------------------------"
      start_time = Time.now
      if profile['regions']['region1']['template'].to_s.include? "cassandra"
        service 'cassandra', @db_regions
      elsif profile['regions']['region1']['template'].to_s.include? "mongodb"
        service 'mongodb', @db_regions
      else
        logger.debug "Database Service Cassandra OR MongoDB, just one of these!"
        exit 0  
      end      
      logger.debug "-----------------------------------------------------------------------------"
      logger.debug "---> Elapsed time for Service [Database]: #{Time.now - start_time} seconds..."
      logger.debug "-----------------------------------------------------------------------------"
      
      logger.debug "--------------------------------------------------------"
      logger.debug "STEP 3: Invoking Service [YCSB] for Benchmark Cluster..."
      logger.debug "--------------------------------------------------------"
      start_time = Time.now
      service 'ycsb', @bench_regions
      logger.debug "-------------------------------------------------------------------------"
      logger.debug "---> Elapsed time for Service [YCSB]: #{Time.now - start_time} seconds..."
      logger.debug "-------------------------------------------------------------------------"

      if profile['snapshot'].to_s == 'true'
        create_snapshot_cassandra
      end
      
      # the next profile
      profile_counter += 1
      
      logger.debug "::: Deleting known_hosts for SSH..."
      system "rvmsudo rm /home/ubuntu/.ssh/known_hosts"
    end    
  end
  
  # ======================================================================== #
  # used to detect how many machines should be created for DATABASE service
  # convention: first place in template
  # e.g.: 3 cassandra+gmond, 2 ycsb --> 3
  # ======================================================================== #
  private
  def template_parse_to_find_machine_number_for_database_service template_string
    found_number = 0
    test = template_string.split " "
    found_number = test[0].to_i
    found_number
  end

  # ======================================================================== #
  # used to detect how many machines should be created for BENCHMARK service
  # convention: direct after the comma
  # e.g.: 3 cassandra+gmond, 2 ycsb --> 2
  # ======================================================================== #
  private
  def template_parse_to_find_machine_number_for_benchmark_service template_string
    found_number = 0
    test = template_string.split ","
    test[1] = test[1].to_s.strip # delete the white spaces
    found_number = test[1].to_s.split(" ")[0]
    found_number
  end
  
  # --- template_string ---
  # 3 cassandra+gmond, 2 ycsb 
  private
  def template_parse_to_find_service template_string
    sub_cluster_arr = []
    
    # ycsb is needed
    if template_string.to_s.include? ","
      sub_cluster_arr = template_string.to_s.split ","
      
      # delete the first and last white spaces in each sub cluster
      for i in 0..(sub_cluster_arr.size - 1)
        sub_cluster_arr[i] = sub_cluster_arr[i].to_s.strip
      end
    
    # ycsb is not needed
    else
      sub_cluster_arr << template_string.to_s.strip
    end

    # validation
    # cassandra | mongoDB 
    if (sub_cluster_arr[0].to_s.include? "cassandra") && (sub_cluster_arr[0].to_s.include? "mongodb")
      logger.debug "::: Cassandra OR MongoDB, not the parallel!"
      exit 0
    end

    sub_cluster_arr
    # sub_cluster_arr[0]: database sub cluster
    # sub_cluster_arr[1]: benchmark sub cluster
  end
  
  # ============================================================================================ #
  # --------------
  # Service Facade
  # --------------
  # used to invoke the corresponding service
  # name: the service to be invoked
  # atribute_hash: contains all needed attributes for the service
  # 
  # ------------------
  # Supported Services
  # ------------------
  # 1.Provision (primary)
  #   Provision machines with the given parameters like provider, region, machine number, machine type.
  #
  # 2.Cassandra (primary)
  #   Deploy a Cassandra cluster in single/multiple region(s) with given database configuration parameters
  # 3.MongoDB (primary)
  #   Deploy a MongoDB cluster in single/multiple region(s) with given database configuration parameters
  # 
  # 4.YCSB (optional)
  #   Deploy a YCSB cluster to benchmark a given database cluster
  # 5.Ganglia (optional)
  #   Deploy Ganglia Agents (gmond) in each node of the given database cluster and Ganglia Central Monitoring (gmetad) in KCSDB Server  
  # ============================================================================================ #
  private
  def service name, attribute_hash
    # SERVICE_ID: 1
    if name == 'provision'
      service_provision attribute_hash

    # SERVICE_ID: 2    
    elsif name == 'cassandra'
      service_cassandra attribute_hash
    elsif name == 'mongodb'
      service_mongodb attribute_hash

    # SERVICE_ID: 3
    elsif name == 'ycsb'
      service_ycsb attribute_hash
    
    # SERVICE_ID: 4
    elsif name == 'ganglia'
      service_ganglia attribute_hash
    else
      logger.debug "::: Service: #{name} is not supported!"
      exit 0  
    end
  end

  # ============================================================================================ #  
  # SERVICE_ID: 1
  # Service Provision
  # used to provision machines in parallel mode
  #
  # primary service
  # this service has to be called always at first to provision machines in cloud infrastructure
  # 
  # -- cloud_config_hash ---
  # provider: aws | rackspace
  # regions:
  #   region1: 
  #     name: us-east-1
  #     machine_type: small     
  #     template: 3 cassandra, 2 ycsb
  #     
  #   region2:
  #     name: us-weast-1
  #     machine_type: small     
  #     template: 2 cassandra, 2 ycsb
  # .....    
  # ============================================================================================ #
  private
  def service_provision cloud_config_hash
    provider = cloud_config_hash['provider']
    region_hash = cloud_config_hash['regions']
    
    # SERVICE_ID: 1.1
    if provider == 'aws'
      service_provision_ec2 region_hash 
    
    # SERVICE_ID: 1.2
    elsif provider == 'rackspace'
      service_provision_rackspace region_hash
    else
      logger.debug "::: Provider: #{provider} is not supported!"
      exit 0
    end
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 1.1
  # provision EC2 machine for database service and benchmark service in parallel mode
  # each thread is a provision_ec2_machine call
  #
  # INPUT:
  #   region1: 
  #     name: us-east-1
  #     machine_type: small     
  #     template: 3 cassandra, 2 ycsb
  #     
  #   region2:
  #     name: us-weast-1
  #     machine_type: small     
  #     template: 2 cassandra
  #
  # OUTPUT:
  # fill the two shared variables
  # --- @db_regions ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]  
  #
  # ---@bench_regions ---
  # region1:
  #   name: us-east-1
  #   ips: [6,7,8]
  # region2:
  #   name: us-west-1
  #   ips: [9,10]
  # ============================================================================================ #
  private
  def service_provision_ec2 cloud_config_hash
    # contains all needed meta info for invoking parallel function later
    parallel_array = []
    
    # build the parallel_array
    # each element of parallel_array is a array once again with following parameters
    # region: e.g. us-east-1
    # ami: e.g. ami-123456
    # flavor: e.g. small
    # key_pair: e.g. KCSDB
    # security_group: e.g. KCSDB
    # name: e.g. cassandra-node-1
    state = get_state
    db_node_counter = 1
    bench_node_counter = 1
    cloud_config_hash.each do |region, values|
      # region
      region_name = values['name']
      
      # ami
      if region_name == 'us-east-1'
        machine_ami = state['chef_client_ami_us_east_1']
      elsif region_name == 'us-west-1'
        machine_ami = state['chef_client_ami_us_west_1']
      elsif region_name == 'us-west-2'
        machine_ami = state['chef_client_ami_us_west_2']
      elsif region_name == 'eu-west-1'
        machine_ami = state['chef_client_ami_eu_west_1']
      else
        logger.debug "Region: #{region_name} is not supported!"
        exit 0
      end
      
      # flavor
      machine_flavor = "m1." + values['machine_type']
      
      # key pair
      key_pair = state['key_pair_name']
      
      # security group
      security_group = state['security_group_name']

      template = values['template']

      # now is the name
      # FIRST, for DATABASE cluster
      base_name = ""
      if template.to_s.include? "cassandra"
        base_name = "cassandra" 
      elsif template.to_s.include? "mongodb"
        base_name = "mongodb"
      else
        logger.debug "Do NOT find database nodes like cassandra or mongodb"
        exit 0
      end
      
      # calculate the machine number of this region for DATABASE from template
      machine_number_for_db = template_parse_to_find_machine_number_for_database_service(template).to_i
      
      # update parallel array
      db_node_name_array = []
      machine_number_for_db.times do
        tmp_array = []

        tmp_array << region_name
        tmp_array << machine_ami
        tmp_array << machine_flavor
        tmp_array << key_pair
        tmp_array << security_group
        tmp_array << "#{base_name}-node-" + db_node_counter.to_s
        
        parallel_array << tmp_array

        db_node_name_array << "#{base_name}-node-" + db_node_counter.to_s
        
        db_node_counter += 1
      end

      # SECOND, for BENCHMARK cluster
      # optional
      base_name = ""
      machine_number_for_bench = 0
      bench_node_name_array = []
      if template.to_s.include? "ycsb"
        base_name = "ycsb" 
        
        # calculate the machine number of this region for DATABASE from template
        machine_number_for_bench = template_parse_to_find_machine_number_for_benchmark_service(template).to_i
        
        # update parallel array
        machine_number_for_bench.times do
          tmp_array = []
  
          tmp_array << region_name
          tmp_array << machine_ami
          
          # LHA, test
          # tmp_array << machine_flavor
          tmp_array << 'm1.xlarge'
          
          tmp_array << key_pair
          tmp_array << security_group
          tmp_array << "#{base_name}-node-" + bench_node_counter.to_s
  
          parallel_array << tmp_array
          
          bench_node_name_array << "#{base_name}-node-" + bench_node_counter.to_s
          
          bench_node_counter += 1
        end
      end
      
      logger.debug "-------------------------"
      logger.debug "Region: #{region_name}"
      logger.debug "Machine number: #{machine_number_for_db + machine_number_for_bench}"
      logger.debug "Machine flavor: #{machine_flavor}"
      logger.debug "Machine image: #{machine_ami}"
      logger.debug "Key pair: #{key_pair}"
      logger.debug "Security group: #{security_group}"
      logger.debug "Node names: "
      logger.debug "-- Database cluster: " ; puts db_node_name_array ;
      logger.debug "-- Benchmark Cluster:" ; puts bench_node_name_array ;
      logger.debug "-------------------------"
    end
    
    # now provision machines in parallel mode
    logger.debug "------------------------------------------------------------------------------------------"
    logger.debug "::: Provisioning ALL machines for DATABASE cluster and BENCHMARK cluster in ALL regions..."
    logger.debug "------------------------------------------------------------------------------------------"
    results = Parallel.map(parallel_array, in_threads: parallel_array.size) do |arr|
      provision_ec2_machine arr[0], arr[1], arr[2], arr[3], arr[4], arr[5]
    end
    
    # update @db_regions
    reg_counter = 1
    
    # us-east-1
    if ! @db_nodes_us_east_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-east-1"
      @db_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-east-1
      
      ips = Hash.new
      ips['ips'] = @db_nodes_us_east_1
      @db_regions["region#{reg_counter}"] = @db_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-east-1
      #   ips: [1,2,3]
      
      reg_counter += 1
    end  
     
    # us-west-1
    if ! @db_nodes_us_west_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-west-1"
      @db_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-west-1
      
      ips = Hash.new
      ips['ips'] = @db_nodes_us_west_1
      @db_regions["region#{reg_counter}"] = @db_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-west-1
      #   ips: [1,2,3]
      
      reg_counter += 1
    end
      
    # us-west-2
    if ! @db_nodes_us_west_2.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-west-2"
      @db_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-west-2
      
      ips = Hash.new
      ips['ips'] = @db_nodes_us_west_2
      @db_regions["region#{reg_counter}"] = @db_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-west-2
      #   ips: [1,2,3]
      
      reg_counter += 1 
    end
    
    # eu-west-1
    if ! @db_nodes_eu_west_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "eu-west-1"
      @db_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: eu-west-1
      
      ips = Hash.new
      ips['ips'] = @db_nodes_eu_west_1
      @db_regions["region#{reg_counter}"] = @db_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: eu-west-1
      #   ips: [1,2,3]
      
      reg_counter += 1 
    end
    
    # update @bench_regions
    reg_counter = 1
    
    # us-east-1
    if ! @bench_nodes_us_east_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-east-1"
      @bench_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-east-1
      
      ips = Hash.new
      ips['ips'] = @bench_nodes_us_east_1
      @bench_regions["region#{reg_counter}"] = @bench_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-east-1
      #   ips: [1,2,3]
      
      reg_counter += 1
    end  
     
    # us-west-1
    if ! @bench_nodes_us_west_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-west-1"
      @bench_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-west-1
      
      ips = Hash.new
      ips['ips'] = @bench_nodes_us_west_1
      @bench_regions["region#{reg_counter}"] = @bench_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-west-1
      #   ips: [1,2,3]
      
      reg_counter += 1
    end
      
    # us-west-2
    if ! @bench_nodes_us_west_2.empty?
      reg_name = Hash.new
      reg_name['name'] = "us-west-2"
      @bench_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: us-west-2
      
      ips = Hash.new
      ips['ips'] = @bench_nodes_us_west_2
      @bench_regions["region#{reg_counter}"] = @bench_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: us-west-2
      #   ips: [1,2,3]
      
      reg_counter += 1 
    end
    
    # eu-west-1
    if ! @bench_nodes_eu_west_1.empty?
      reg_name = Hash.new
      reg_name['name'] = "eu-west-1"
      @bench_regions["region#{reg_counter}"] = reg_name
      # region1
      #   name: eu-west-1
      
      ips = Hash.new
      ips['ips'] = @bench_nodes_eu_west_1
      @bench_regions["region#{reg_counter}"] = @bench_regions["region#{reg_counter}"].merge ips
      # region1
      #   name: eu-west-1
      #   ips: [1,2,3]
      
      reg_counter += 1 
    end
  end

  # ============================================================================================ #  
  # core function
  # provision a new EC2 machine
  # used for each thread
  # a dedicated fog object is responsible for creating a machine
  # 
  # INPUT:
  # region: e.g. us-east-1
  # ami: ami-123456
  # flavor: small
  # key_pair: KCSDB
  # security_group: KCSDB
  # name: cassandra-node-1
  #
  # OUTPUT:
  # the IP of the newly created EC2 machine will be added into the corresponding
  # shared variable, e.g. @db_nodes_us_east_1
  # ============================================================================================ #
  private
  def provision_ec2_machine region, ami, flavor, key_pair, security_group, name
    logger.debug "::: Provisioning machine: #{name}..."
    # synchronize stdout
    $stdout.sync = true
    
    # create a fog object in the given region with the corresponding provider (aws, rackspace)
    ec2 = create_fog_object 'aws', region, 'compute'
    
    # server definition
    server_def = {
      image_id: ami,
      flavor_id: flavor,
      key_name: key_pair,
      groups: security_group,
      block_device_mapping: [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 20 }] # big enough EBS volume for big data in Cassandra
    }
    
    # create server with the tag name
    server = ec2.servers.create server_def
    sleep 3 # a small pause
    ec2.tags.create key: 'Name', value: name, resource_id: server.id

    # wait until the server is ready
    logger.debug "::: Waiting for machine: #{server.id}..."
    server.wait_for { print "."; ready? }
    # the machine is updated with public IP address
    puts "\n"

    # check sshd in the server
    print "." until tcp_test_ssh(server.public_ip_address) { sleep 1 }

    # public IPv4 of the newly created server
    ip = server.public_ip_address
    
    # Adding a newly created server to the nodes list
    # depends on region and cluster type (database or benchmark)
    # lock    
    @mutex.synchronize do
      if name.to_s.include? "cassandra" or name.to_s.include? "mongodb" # add to database cluster
        if region == "us-east-1" # in us-east-1
          @db_nodes_us_east_1 << ip
        elsif region == "us-west-1" # in us-west-1
          @db_nodes_us_west_1 << ip
        elsif region == "us-west-2" # in us-west-2
          @db_nodes_us_west_2 << ip
        elsif region == "eu-west-1" # in eu-west-1
          @db_nodes_eu_west_1 << ip  
        end
      elsif name.to_s.include? "ycsb" # add to benchmark cluster
        if region == "us-east-1" # in us-east-1
          @bench_nodes_us_east_1 << ip
        elsif region == "us-west-1" # in us-west-1
          @bench_nodes_us_west_1 << ip
        elsif region == "us-west-2" # in us-west-2
          @bench_nodes_us_west_2 << ip
        elsif region == "eu-west-1" # in eu-west-1
          @bench_nodes_eu_west_1 << ip  
        end        
      end
    end
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 1.2
  # ============================================================================================ #
  private
  def service_provision_rackspace cloud_config_hash, flag
    
  end
  
  # ============================================================================================ #
  # provision a new Rackspace machine
  # used for each thread
  # ============================================================================================ #
  private
  def provision_rackspace_machine
    
  end

  # ============================================================================================ #  
  # SERVICE_ID: 2
  # Service Cassandra
  # database service
  # used to deploy a database cluster in single/multiple region(s) in parallel mode
  #
  # primary service
  # a database service (Cassandra | MongoDB) has always to be called
  #
  # --- (should be) cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4 (will be calculated)
  #   tokens: [0,121212,352345] (will be calculated)
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4 (will be calculated)
  #   tokens: [4545, 32412341234] (will be calculated)
  # attributes:
  #   replication_factor: 2,2 (will be fetched)
  # ============================================================================================ #
  private
  def service_cassandra cassandra_config_hash
    logger.debug "--------------------------"
    logger.debug "::: Cassandra Config Hash:"
    logger.debug "--------------------------"
    puts cassandra_config_hash
    
    # calculate the tokens for nodes in single/multiple regions
    # SERVICE_ID: 2.1
    cassandra_config_hash = calculate_token_position cassandra_config_hash

    # calculate the seeds for nodes in single/multiple regions
    # SERVICE_ID: 2.2
    cassandra_config_hash = calculate_seed_list cassandra_config_hash    
    
    # fetch the attributes for nodes
    # SERVICE_ID: 2.3
    cassandra_config_hash = fetch_attributes_for_cassandra cassandra_config_hash
    logger.debug "-----------------------------------------------------------"
    logger.debug "::: Cassandra Config Hash (incl. Tokens, Seeds, Attributes)"
    logger.debug "-----------------------------------------------------------"
    puts cassandra_config_hash
    
    # check multiple regions or single region
    single_region_hash = Hash.new
    if cassandra_config_hash.has_key? "region2" # at least region2 exists
      single_region_hash['single_region'] = 'false'
    else
      single_region_hash['single_region'] = 'true'
    end
    
    
    # the first node of Cassandra cluster is the collector of the whole cluster
    gmond_collector_hash = Hash.new
    gmond_collector_hash['gmond_collector'] = @db_regions['region1']['ips'][0]
    
    # update default.rb
    # SERVICE_ID: 2.4
    default_rb_hash = cassandra_config_hash['attributes'].merge single_region_hash
    default_rb_hash = default_rb_hash.merge default_rb_hash    
    update_default_rb_of_cookbooks default_rb_hash
        
    # deploy Cassandra
    # SERVICE_ID: 2.5
    deploy_cassandra cassandra_config_hash
    
    # install OpsCenter Agent
    # SERVICE_ID: 2.8
    #install_opscenter_agent
    
    # for single region mode only
    # make a small pause, the cassandra server needs a little time to be ready
    if single_region_hash['single_region'] == 'true'
      sleep 60
    end
    
    # configure cassandra via cassandra-cli
    # SERVICE_ID: 2.6
    configure_cassandra cassandra_config_hash

    # backup cassandra if needed
    # SERVICE_ID: 2.7
    if cassandra_config_hash['attributes']['backup'].to_s == 'true'
      backup_cassandra  
    end
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.1
  # token positions for all node in single/multiple regions
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # ============================================================================================ #
  private
  def calculate_token_position cassandra_config_hash 
    logger.debug "-------------------------"
    logger.debug "::: Calculating tokens..."
    logger.debug "-------------------------"
    
    # generate parameter for tokentool.py
    param = ""
    cassandra_config_hash.each do |key, values|
      param << values['ips'].size.to_s << " "
    end  

    # call tokentool.py    
    system "python #{Rails.root}/chef-repo/.chef/sh/tokentool.py #{param} > #{Rails.root}/chef-repo/.chef/tmp/tokens.json"
    json = File.open("#{Rails.root}/chef-repo/.chef/tmp/tokens.json","r")
    parser = Yajl::Parser.new
    token_hash = parser.parse json
    # {
      # "0": {
          # "0": 0, 
          # "1": 56713727820156410577229101238628035242, 
          # "2": 113427455640312821154458202477256070485
      # }, 
      # "1": {
          # "0": 28356863910078205288614550619314017621, 
          # "1": 85070591730234615865843651857942052863, 
          # "2": 141784319550391026443072753096570088106
      # }
    # }

    # adding tokens into cassandra_config_hash
    token_hash.each do |key, values|
      tmp_arr = values.values # tmp_arr contains tokens for the region
      t = Hash.new
      t['tokens'] = tmp_arr
      cassandra_config_hash["region#{key.to_i + 1}"] = cassandra_config_hash["region#{key.to_i + 1}"].merge t
    end  

    cassandra_config_hash
  end

  # ============================================================================================ #  
  # SERVICE_ID: 2.2
  # seed list for each region
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # ============================================================================================ #
  private
  def calculate_seed_list cassandra_config_hash
    # 50% nodes are seeds in each region
    # at least one node
    fraction = 0.5
    
    logger.debug "------------------------"
    logger.debug "::: Calculating seeds..."
    logger.debug "------------------------"
    seeds = ""
    cassandra_config_hash.each do |key, values|
      if values['ips'].size == 1 # only one node, this node is seed 
        seeds << values['ips'][0] << ","
      else # more than one node
        number_of_seeds = values['ips'].size * fraction
        for i in 0..(number_of_seeds - 1) do
          seeds << values['ips'][i] << ","
        end
      end
    end
    seeds = seeds[0..-2] # delete the last comma
    
    cassandra_config_hash.each do |key,value|
      seeds_hash = Hash.new
      seeds_hash['seeds'] = seeds
      cassandra_config_hash[key] = cassandra_config_hash[key].merge seeds_hash
    end

    cassandra_config_hash
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.3
  # fetch attributes from definitions
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # ============================================================================================ #
  private
  def fetch_attributes_for_cassandra cassandra_config_hash
    @service_array.each do |service|
      if service['name'] == 'cassandra'
        cassandra_config_hash['attributes'] = service['attributes']
      end
    end
    cassandra_config_hash  
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.4
  # update the parameters that are written in cookbooks/cassandra/attributes/default.rb
  # and upload cookbooks once again
  #
  # --- param_hash ---
  # seeds: 1,2,3
  # ...
  # ============================================================================================ #
  private
  def update_default_rb_of_cookbooks param_hash
    logger.debug "------------------------------------------------"
    logger.debug "::: Updating default.rb of cassandra cookbook..."
    logger.debug "------------------------------------------------"
    file_name = "#{Rails.root}/chef-repo/cookbooks/cassandra/attributes/default.rb"
    default_rb = File.read file_name
    param_hash.each do |key, value|
      default_rb.gsub!(/.*default\[:cassandra\]\[:#{key}\].*/, "default[:cassandra][:#{key}] = \'#{value}\'")
    end  
    File.open(file_name,'w') {|f| f.write default_rb }
    
    logger.debug "-----------------------------------------"
    logger.debug "::: Uploading cookbooks to Chef Server..."
    logger.debug "-----------------------------------------"
    system "rvmsudo knife cookbook upload cassandra --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.5
  # deploy cassandra in all region in parallel mode
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,2  
  # ============================================================================================ #
  private
  def deploy_cassandra cassandra_config_hash
    recipe = "recipe[cassandra]"
    region_counter = 1
    cassandra_node_counter = 1
    parallel_array = []
    
    # build parallel_array
    until ! cassandra_config_hash.has_key? "region#{region_counter}" do
      current_region = cassandra_config_hash["region#{region_counter}"]
      
      node_ip_array = current_region['ips']
      token_array = current_region['tokens']
      seeds = current_region['seeds']
      
      logger.debug "---------------------------------"
      logger.debug "Region: #{current_region['name']}"
      
      for j in 0..(node_ip_array.size - 1) do
        tmp_array = []
        
        node_ip = node_ip_array[j] # for which node
        logger.debug "Node IP: #{node_ip}"
      
        token = token_array[j] # which token position
        logger.debug "--- Token: #{token}"
        
        node_name = "cassandra-node-" << cassandra_node_counter.to_s
        cassandra_node_counter += 1
        logger.debug "--- Node Name: #{node_name}"
        
        token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
        File.open(token_file,"w") do |file|
          file << "#!/usr/bin/env bash" << "\n"
          file << "echo #{token} | tee /home/ubuntu/token.txt" << "\n"
          file << "echo #{seeds} | tee /home/ubuntu/seeds.txt" << "\n"
        end

        tmp_array << node_ip
        tmp_array << token
        tmp_array << node_name
        tmp_array << recipe
        tmp_array << current_region['name']
        
        parallel_array << tmp_array
      end
      
      logger.debug "Seeds: #{seeds}"
      logger.debug "---------------------------------"

      region_counter += 1
    end

    logger.debug "-------------------------------------------"
    logger.debug "::: Deploying #{parallel_array.size} CASSANDRA nodes in ALL regions..."
    logger.debug "-------------------------------------------"
    results = Parallel.map(parallel_array, in_threads: parallel_array.size) do |arr|
      system(knife_bootstrap arr[0], arr[1], arr[2], arr[3], arr[4])
    end

    logger.debug "---------------------------------------------------------"
    logger.debug "::: Deleting all token temporary files in KCSDB Server..."
    logger.debug "---------------------------------------------------------"
    system "rm #{Rails.root}/chef-repo/.chef/tmp/*.sh"
  end
  
  # =================================================================================================== #
  # SERVICE_ID: 2.5.1
  # knife bootstrap command string
  #
  # INPUT:
  # node: the IP address of the machine to be bootstrapped
  # token: which token position should the node have, the token is passed by KCSDB Server in form of a script for EC2
  # name: name of the node in Chef Server
  # recipe: which recipe should be used: cassandra or ycsb
  # region: which region --> find the corresponding private key
  #
  # OUTPUT:
  # a command string for knife bootstrap
  # =================================================================================================== #
  private
  def knife_bootstrap node, token, name, recipe, region
    $stdout.sync = true
    
    state = get_state

    key_pair = state['key_pair_name']
    chef_client_identity_file = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    
    chef_client_ssh_user = state['chef_client_ssh_user']
    chef_client_bootstrap_version = state['chef_client_bootstrap_version']
    chef_client_template_file = state['chef_client_template_file']
    
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"

    logger.debug "-----------------------------------------------------"
    logger.debug "::: Uploading the token file to the node: #{node}... "
    logger.debug "-----------------------------------------------------"
    token_file = "#{Rails.root}/chef-repo/.chef/tmp/#{token}.sh"
    system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{token_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"
    logger.debug "::: Uploading the token file to the node: #{node}... [OK]"
      
    logger.debug "-----------------------------------------------------"
    logger.debug "::: Executing the token file in the node: #{node}... "
    logger.debug "-----------------------------------------------------"
    system "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node} 'sudo bash #{token}.sh'"
    logger.debug "::: Executing the token file in the node: #{node}... [OK]"
      
    if File.exist? "#{Rails.root}/chef-repo/.chef/tmp/zoo.cfg"
      logger.debug "---------------------------------------------"
      logger.debug "::: Uploading zoo.cfg to the node: #{node}..."
      logger.debug "---------------------------------------------"
      zoo_cfg_file = "#{Rails.root}/chef-repo/.chef/tmp/zoo.cfg"  
      system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{zoo_cfg_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"     
    end
    
    if File.exist? "#{Rails.root}/chef-repo/.chef/tmp/barrier_size.txt"
      logger.debug "---------------------------------------------"
      logger.debug "::: Uploading barrier_size.txt to the node: #{node}..."
      logger.debug "---------------------------------------------"
      barrier_size_file = "#{Rails.root}/chef-repo/.chef/tmp/barrier_size.txt"  
      system "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{barrier_size_file} #{chef_client_ssh_user}@#{node}:/home/#{chef_client_ssh_user}"     
    end

    knife_bootstrap_string = ""
       
    knife_bootstrap_string << "rvmsudo knife bootstrap #{node} "
    knife_bootstrap_string << "--config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    knife_bootstrap_string << "--identity-file #{chef_client_identity_file} "
    knife_bootstrap_string << "--ssh-user #{chef_client_ssh_user} "
    knife_bootstrap_string << "--bootstrap-version #{chef_client_bootstrap_version} "
    knife_bootstrap_string << "--template-file #{chef_client_template_file} "
    knife_bootstrap_string << "--run-list \'#{recipe}\' "
    knife_bootstrap_string << "--node-name \'#{name}\' "
    knife_bootstrap_string << "--yes "
    knife_bootstrap_string << "--no-host-key-verify "
    knife_bootstrap_string << "--sudo "
    
    logger.debug "----------------------------------------"
    logger.debug "::: Knife bootstrapping a new machine..."
    logger.debug "::: The knife bootstrap command:"
    logger.debug "----------------------------------------" 
    logger.debug knife_bootstrap_string
    knife_bootstrap_string
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.6
  # configure cassandra via cassandra-cli
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,1
  # ============================================================================================ #
  private
  def configure_cassandra cassandra_config_hash
    logger.debug "------------------------------------"
    logger.debug "::: Configuring Cassandra cluster..."
    logger.debug "------------------------------------"
    
    # delete the recipe[cassandra] in cassandra-node-1
    system "rvmsudo knife node run_list remove cassandra-node-1 'recipe[cassandra]' --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
    
    # update replication_factor
    rep_fac_arr = []
    if cassandra_config_hash['attributes']['replication_factor'].to_s.include? "," # multiple regions
      rep_fac_arr = cassandra_config_hash['attributes']['replication_factor'].to_s.split ","
      
      # delete the first and last white spaces
      for i in 0..(rep_fac_arr.size - 1)
        rep_fac_arr[i] = rep_fac_arr[i].to_s.strip
      end
    else # single region
      rep_fac_arr << cassandra_config_hash['attributes']['replication_factor'].to_s.strip
    end

    # us-east-1:2,us-west-1:1
    for i in 0..(rep_fac_arr.size - 1)
      rep_fac_arr[i] = cassandra_config_hash["region#{i + 1}"]['name'] + ":" + rep_fac_arr[i]  
    end
    replication_factor = ""
    rep_fac_arr.each do |rep|
      replication_factor << rep << ","
    end
    replication_factor = replication_factor[0..-2] # delete the last comma
    
    # bug fix
    # http://stackoverflow.com/questions/11024042/how-to-configure-cassandra-to-work-across-multiple-ec2-regions-with-ec2multiregi
    # for the issue
    # https://issues.apache.org/jira/browse/CASSANDRA-4026
    replication_factor.gsub!(/us-east-1/,"us-east")
    replication_factor.gsub!(/us-west-1/,"us-west")
    replication_factor.gsub!(/us-west-2/,"us-west2")
    replication_factor.gsub!(/eu-west-1/,"eu-west")
    
    rep_fac_hash = Hash.new
    rep_fac_hash['replication_factor'] = replication_factor
    
    update_default_rb_of_cookbooks rep_fac_hash
    
    system "rvmsudo knife node run_list add cassandra-node-1 'recipe[cassandra::configure_cluster]' --config #{Rails.root}/chef-repo/.chef/conf/knife.rb"
    
    # invoke the recipe[cassandra::configure_cluster]
    state = get_state
    ssh_user = state['chef_client_ssh_user']
    key_pair = state['key_pair_name']
    region = cassandra_config_hash['region1']['name'] # cassandra-node-1 is always in region1
    
    cmd = ""
    cmd << "rvmsudo knife ssh name:cassandra-node-1 --config #{Rails.root}/chef-repo/.chef/conf/knife.rb "
    cmd << "--ssh-user #{ssh_user} "
    cmd << "--identity-file #{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem "
    cmd << "--attribute ec2.public_hostname "
    cmd << "\'sudo chef-client\'"
    
    puts cmd
    
    system cmd
  end

  # ============================================================================================ #
  # SERVICE_ID: 2.7
  # backup cassandra cluster
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,1
  #   backup: true
  # ============================================================================================ #
  private
  def backup_cassandra
    logger.debug "-----------------------------------------------------------------------------------------"
    logger.debug "::: Backing up snapshots for all Cassandra nodes..."
    logger.debug "[NOTE] Backup Function works in the moment only for single region, and for only us-east-1"
    logger.debug "-----------------------------------------------------------------------------------------"
    start_time = Time.now
    
    ips_arr = @db_regions['region1']['ips']
    para_arr = []
        
    counter = 1
    ips_arr.each do |ip|
      if ip.include? ',' then ip = ip.chomp ',' end
      tmp_arr = []
      tmp_arr << ip
      tmp_arr << counter
      para_arr << tmp_arr
      counter += 1
    end
        
    $stdout.sync = true
    
    state = get_state

    key_pair = state['key_pair_name']
    region = 'us-east-1'
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"
    chef_client_identity_file = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    chef_client_ssh_user = state['chef_client_ssh_user']
    download_snapshot_from_s3_file = "#{Rails.root}/chef-repo/.chef/sh/backup_snapshot.sh"
        
    results = Parallel.map(para_arr, in_threads: para_arr.size) do |node|
      cmd = "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{download_snapshot_from_s3_file} #{chef_client_ssh_user}@#{node[0]}:/home/#{chef_client_ssh_user}"          
      puts cmd
      system cmd
  
      cmd = "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node[0]} 'bash /home/ubuntu/backup_snapshot.sh #{node[1]}'"
      puts cmd
      system cmd
    end
    
    logger.debug "---------------------------------------------------------------------------"
    logger.debug "---> Elapsed time for Service [Backup]: #{Time.now - start_time} seconds..."
    logger.debug "---------------------------------------------------------------------------"
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.8
  # create snapshot for cassandra cluster
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,1
  #   backup: true
  # ============================================================================================ #
  private
  def create_snapshot_cassandra
    logger.debug "-------------------------------------------------------------------------------------------"
    logger.debug "::: Creating snapshots for all Cassandra nodes..."
    logger.debug "[NOTE] Snapshot Function works in the moment only for single region, and for only us-east-1"
    logger.debug "-------------------------------------------------------------------------------------------"
    start_time = Time.now
        
    ips_arr = @db_regions['region1']['ips']
    para_arr = []
        
    counter = 1
    ips_arr.each do |ip|
      if ip.include? ',' then ip = ip.chomp ',' end
      tmp_arr = []
      tmp_arr << ip
      tmp_arr << counter
      para_arr << tmp_arr
      counter += 1
    end
        
    $stdout.sync = true
    
    state = get_state

    key_pair = state['key_pair_name']
    region = 'us-east-1'
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"
    chef_client_identity_file = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    chef_client_ssh_user = state['chef_client_ssh_user']
    upload_snapshot_to_s3_file = "#{Rails.root}/chef-repo/.chef/sh/create_snapshot.sh"
    aws_access_key_id = state['aws_access_key_id']
    aws_secret_access_key = state['aws_secret_access_key']
        
    results = Parallel.map(para_arr, in_threads: para_arr.size) do |node|
      cmd = "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{upload_snapshot_to_s3_file} #{chef_client_ssh_user}@#{node[0]}:/home/#{chef_client_ssh_user}"          
      puts cmd
      system cmd
  
      cmd = "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{node[0]} 'bash /home/ubuntu/create_snapshot.sh #{node[1]} #{aws_access_key_id} #{aws_secret_access_key}'"
      puts cmd
      system cmd
    end
        
    logger.debug "-----------------------------------------------------------------------------"
    logger.debug "---> Elapsed time for Service [Snapshot]: #{Time.now - start_time} seconds..."
    logger.debug "-----------------------------------------------------------------------------"
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 2.9
  # install opscenter agents
  #
  # --- cassandra_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  # attributes:
  #   replication_factor: 2,1
  #   backup: true
  # ============================================================================================ #
  private
  def install_opscenter_agent
    logger.debug "----------------------------------------------------------------------------------------------------------"
    logger.debug "::: Installing OpsCenter Agent in Cassandra Node..."
    logger.debug "[NOTE] Install OpsCenter Agent Function works in the moment only for single region, and for only us-east-1"
    logger.debug "----------------------------------------------------------------------------------------------------------"
    start_time = Time.now
    
    ips_arr = @db_regions['region1']['ips']
    para_arr = []
        
    ips_arr.each do |ip|
      if ip.include? ',' then ip = ip.chomp ',' end
      para_arr << ip
    end
        
    $stdout.sync = true
    
    state = get_state

    key_pair = state['key_pair_name']
    region = 'us-east-1'
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"
    chef_client_identity_file = "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{region}.pem"
    chef_client_ssh_user = state['chef_client_ssh_user']
    opscenter_agent_tarball_file = "/usr/share/opscenter/agent.tar.gz"
    install_opscenter_agent_file = "#{Rails.root}/chef-repo/.chef/sh/install_opscenter_agent.sh"
        
    capture_private_ip_of_kcsdb_server
    
    kcsdb_private_ip_address = ""
    File.open("#{Rails.root}/chef-repo/.chef/tmp/kcsdb_private_ip.txt","r").each do |line|
      kcsdb_private_ip_address = line.to_s.strip
    end    
        
    results = Parallel.map(para_arr, in_threads: para_arr.size) do |ip|
      cmd = "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{opscenter_agent_tarball_file} #{chef_client_ssh_user}@#{ip}:/home/#{chef_client_ssh_user}"          
      puts "Command: #{cmd}"
      system cmd
      
      cmd = "rvmsudo scp -i #{chef_client_identity_file} #{no_checking} #{install_opscenter_agent_file} #{chef_client_ssh_user}@#{ip}:/home/#{chef_client_ssh_user}"          
      puts "Command: #{cmd}"
      system cmd
      
      cmd = "rvmsudo ssh -i #{chef_client_identity_file} #{no_checking} #{chef_client_ssh_user}@#{ip} 'sudo bash /home/ubuntu/install_opscenter_agent.sh #{kcsdb_private_ip_address}'"
      puts "Command: #{cmd}"
      system cmd
    end
    
    logger.debug "--------------------------------------------------------------------------------------------"
    logger.debug "---> Elapsed time for Service [Install OpsCenter Agent]: #{Time.now - start_time} seconds..."
    logger.debug "--------------------------------------------------------------------------------------------"
  end
  # ============================================================================================ # 
  # SERVICE_ID: 3 
  # install ycsb cluster in each region
  #
  # uses 2 shared hash maps
  #
  # --- @db_regions ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  #   seeds: 1,2,4
  #   tokens: [0,121212,352345]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  #   seeds: 1,2,4
  #   tokens: [4545, 32412341234]
  #
  # ---@bench_regions = ycsb_config_hash---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # attributes:
  #   workload_model: hotspot
  # ============================================================================================ #
  private
  def service_ycsb ycsb_config_hash
    logger.debug "-----------------"    
    logger.debug "YCSB Config Hash:"
    logger.debug "-----------------"
    puts ycsb_config_hash
    
    # fetch attributes
    # SERVICE_ID: 3.1
    ycsb_config_hash = fetch_attributes_for_ycsb ycsb_config_hash
    
    logger.debug "------------------------------------"    
    logger.debug "YCSB Config Hash (incl. Attributes):"
    logger.debug "------------------------------------"
    puts ycsb_config_hash
    
    # deploy ycsb for each region in parallel mode
    # SERVICE_ID: 3.2
    deploy_ycsb ycsb_config_hash
    
    # start all YCSB clients in all regions
    start_all_ycsb_clients ycsb_config_hash
    
    get_values_from_mbean_over_jmx
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 3.1
  # fetch attributes from definitions
  #
  # --- ycsb_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # ============================================================================================ #
  private
  def fetch_attributes_for_ycsb ycsb_config_hash
    @service_array.each do |service|
      if service['name'] == 'ycsb'
        ycsb_config_hash['attributes'] = service['attributes']
      end
    end
    ycsb_config_hash  
  end
  
  # ============================================================================================ #
  # SERVICE_ID: 3.2
  # deploy ycsb in each region in parallel mode (for each region)
  #
  # --- ycsb_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # attributes:
  #   workload_model: hotspot  
  # ============================================================================================ #
  private
  def deploy_ycsb ycsb_config_hash
    logger.debug "-------------------------"
    logger.debug "::: Generating zoo.cfg..."
    logger.debug "-------------------------"
    
    # fetch IPs for ycsb_node_array in all regions
    region_counter = 1
    ycsb_node_array = []
    until ! ycsb_config_hash.has_key? "region#{region_counter}" do
      current_region = ycsb_config_hash["region#{region_counter}"]
      
      # IPs in the current region
      node_ip_array = current_region['ips']
      
      # merge with the ycsb_node_array
      ycsb_node_array += node_ip_array
       
      region_counter += 1  
    end

    # write zoo.cfg
    zoo_cfg_file = "#{Rails.root}/chef-repo/.chef/tmp/zoo.cfg"
    File.open(zoo_cfg_file,"w") do |file|
      file << "tickTime=2000" << "\n"
      file << "initLimit=10" << "\n"
      file << "syncLimit=5" << "\n"
      file << "dataDir=/home/ubuntu/zk" << "\n"
      file << "clientPort=2181" << "\n"
      for i in 0..(ycsb_node_array.size - 1)
        file << "server.#{i + 1}=#{ycsb_node_array[i]}:2888:3888" << "\n"
      end
    end
    
    logger.debug "-------------------------------"
    logger.debug "::: Generating barrier_size.txt"
    logger.debug "-------------------------------"
    barrier_size_file = "#{Rails.root}/chef-repo/.chef/tmp/barrier_size.txt"
    File.open(barrier_size_file,'w') do |file|
      file << ycsb_node_array.size
    end
    
    # iterate each region in ycsb_config_hash
    # build parallel_array
    recipe = 'recipe[ycsb]'
    region_counter = 1
    ycsb_node_counter = 1
    parallel_array = []
    until ! ycsb_config_hash.has_key? "region#{region_counter}" do
      ycsb_current_region = ycsb_config_hash["region#{region_counter}"]
      cassandra_current_region = @db_regions["region#{region_counter}"]
      
      ycsb_node_ip_array = ycsb_current_region['ips']
      cassandra_node_ip_array = cassandra_current_region['ips']
      
      # contain all Cassandra's IPs in the current region
      hosts = ""
      cassandra_node_ip_array.each do |ip|
        hosts += ip.to_s << ","
      end
      hosts = hosts[0..-2] # delete the last comma
      
      logger.debug "--------------------------------------"
      logger.debug "Region: #{ycsb_current_region['name']}"
      
      for j in 0..(ycsb_node_ip_array.size - 1) do
        tmp_array = []
        
        ycsb_node_ip = ycsb_node_ip_array[j] # IP of YCSB node
        logger.debug "YCSB Node IP: #{ycsb_node_ip}"
        
        logger.debug "--- YCSB ID: #{ycsb_node_counter}"
        
        ycsb_node_name = "ycsb-node-" << ycsb_node_counter.to_s
        logger.debug "--- YCSB Node Name: #{ycsb_node_name}"
        
        ycsb_id_file = "#{Rails.root}/chef-repo/.chef/tmp/#{ycsb_node_counter}.sh"
        File.open(ycsb_id_file,"w") do |file|
          file << "#!/usr/bin/env bash" << "\n"
          file << "echo #{ycsb_node_counter} | tee /home/ubuntu/myid" << "\n"
          file << "echo #{hosts} | tee /home/ubuntu/hosts.txt" << "\n"
        end

        tmp_array << ycsb_node_ip
        tmp_array << ycsb_node_counter
        tmp_array << ycsb_node_name
        tmp_array << recipe
        tmp_array << ycsb_current_region['name']
        
        parallel_array << tmp_array
        
        ycsb_node_counter += 1
      end

      logger.debug "Target Database IPs: #{hosts}"
      logger.debug "All YCSB Node IPs: #{ycsb_node_array}"
      logger.debug "--------------------------------------"

      region_counter += 1
    end

    logger.debug "----------------------------------"
    logger.debug "::: Deploying #{parallel_array.size} YCSB nodes in ALL regions..."
    logger.debug "----------------------------------"
    results = Parallel.map(parallel_array, in_threads: parallel_array.size) do |arr|
      system(knife_bootstrap arr[0], arr[1], arr[2], arr[3], arr[4])
    end
      
    logger.debug "---------------------------------------------------------"
    logger.debug "::: Deleting all token temporary files in KCSDB Server..."
    logger.debug "---------------------------------------------------------"
    system "rm #{Rails.root}/chef-repo/.chef/tmp/*.sh"

    logger.debug "-----------------------"
    logger.debug "::: Deleting zoo.cfg..."
    logger.debug "-----------------------"
    system "rm #{Rails.root}/chef-repo/.chef/tmp/zoo.cfg"
    
    logger.debug "--------------------------------"
    logger.debug "::: Deleting barrier_size.txt..."
    logger.debug "--------------------------------"
    system "rm #{Rails.root}/chef-repo/.chef/tmp/barrier_size.txt"
  end

  # ============================================================================================ #
  # SERVICE_ID: 3.3
  # start all YCSB clients via ssh
  #
  # --- ycsb_config_hash ---
  # region1:
  #   name: us-east-1
  #   ips: [1,2,3]
  # region2:
  #   name: us-west-1
  #   ips: [4,5]
  # attributes:
  #   workload_model: hotspot  
  # ============================================================================================ #
  private
  def start_all_ycsb_clients ycsb_config_hash
    # LOADING or TRANSACTION phase
    load = ycsb_config_hash['attributes']['load']
    
    parallel_array = []
    region_counter = 1
    
    state = get_state
    key_pair = state['key_pair_name']

    until ! ycsb_config_hash.has_key? "region#{region_counter}" do
      current_region = ycsb_config_hash["region#{region_counter}"]
      puts "Current region:"
      puts current_region
      
      current_region['ips'].each do |ip|
        tmp_arr = []
        
        # private key
        tmp_arr << "#{Rails.root}/chef-repo/.chef/pem/#{key_pair}-#{current_region['name']}.pem"
        
        # ip
        tmp_arr << ip
        
        parallel_array << tmp_arr  
      end
      
      # the next region
      region_counter += 1
    end
    
    no_checking = "-o 'UserKnownHostsFile /dev/null' -o StrictHostKeyChecking=no"
    
    # ssh
    @sleep_array = []
    for s in 0..(parallel_array.size - 1) do
      @sleep_array << (s * 5)
    end
    # @sleep_array = [0,5,10,..]
    
    @sleep_array = @sleep_array.reverse
    # @sleep_array = [..,10,5,0]

    # getting all workload attributes that are defined in profile
    attributes = ycsb_config_hash['attributes']
    
    heap_size = ""
    
    attributes_string = ""
    attributes.each do |key, value|
      if key != "heap_size"
        if key == "measurementtype" || key == "timeseries.granularity"
          attributes_string << "-p #{key}=#{value} "  
        else
          attributes_string << "-p phase1.#{key}=#{value} " # use only single phase for YCSB++
        end
      else
        heap_size = value
      end
    end  
    
    logger.debug "--------------------------------"
    logger.debug "::: Invoking ALL YCSB clients..."
    logger.debug "--------------------------------"
    
    # LOADING or TRANSACTION phase
    if load.to_s == 'false'
      load = 'run'
    elsif load.to_s == 'true'
      load = 'load'  
    end
    
    results = Parallel.map(parallel_array, in_threads: parallel_array.size) do |block|
      sleep_time = 0
      @mutex.synchronize do
        sleep_time = @sleep_array.pop # first come, first has to wait less  
      end
      
      sleep sleep_time
      
      cmd = "rvmsudo ssh -i #{block[0]} #{no_checking} ubuntu@#{block[1]} 'sudo /home/ubuntu/ycsb/bin/ycsb #{heap_size} #{load} cassandra-10 -P /home/ubuntu/ycsb/workloads/workload_unique -s #{attributes_string}'"
      
      logger.debug "YCSB command:"
      puts cmd
      
      system cmd # invoke A YCSB client
    end
  end
  # --------------------------------------------------------------------------------------------#
  
  private
  def get_values_from_mbean_over_jmx
    requester_path = "#{Rails.root}/chef-repo/.chef/sh/requester.rb"
    
    #host = @db_regions['region1']['ips'][0]
    #if host.include? ',' then host = host.chomp ',' end
    
    #requester = File.read requester_path
    #requester.gsub!(/host = ".*/,"host = \"#{host}\"")
    #File.open(requester_path,'w'){|f| f.write requester}
    
    puts "Changing jruby mode"
    system ". /home/ubuntu/.rvm/scripts/rvm"
    system "/bin/bash --login rvm use jruby"
    system "jruby -S #{requester_path}"
    system "rvm --default use 1.9.3"
    #system "bash #{Rails.root}/chef-repo/.chef/sh/invoke_requester.sh"
  end
  
  
  
  # -------------------------------------------------------------------------------------------- #
  private
  def service_mongodb mongodb_config_hash
    
  end
  # -------------------------------------------------------------------------------------------- #  
  
  private
  def service_gmond attribute_array
    logger.debug "::: Service: Gmond is being deployed..."
  end
end