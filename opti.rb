class Pack # sample call: a = Pack.new(10, 24, 400.0, .999, 1) 
    def initialize (xsize, ysize, initialTemp, decreaseRate, stopTemp, initialState)# the initialize function is called when a new instance of pack is made
        @numberOfRows = ysize #how many rows of parallel packs will the operation take
        @cellsPerRow = xsize # how many per row
        @battery = Array.new(@cellsPerRow, 1) # a class storable value for the future battery array
        @systemTemp = initialTemp # the temperature of the system
        @dictionary = '' # empty for now, will eventually contain an ordered array or hash with a useful feature for print out
        @decreaseRate = decreaseRate# how quickly temperature shall decrease
        @cycles = (Math.log(stopTemp/initialTemp)/Math.log(decreaseRate)).to_i # computed from initial temp and decrease rate
        @readIn = initialState # initial organization
        puts 'Optimization will attempt ' + @cycles.to_s + ' trades'
    end
    def spawnPack # call this to initialize the battery
        internalResistances = 
       [8,   2,   2,   7,   2,   8,   7,   1,   1,   7,   2,   8,   
        6,   1,   2,   6,   1,   6,   6,   2,   3,   6,   1,   6,   
        5,   6,   8,   4,   6,   4,   4,   7,   6,   4,   6,   2,   
        4,   6,   7,   3,   7,   3,   2,   7,   7,   2,   6,   1, 
        
        2,   6,   2,   7,   7,   7,   2,   7,   7,   2,   2,   2,   
        1,   5,   1,   5,   5,   5,   2,   5,   6,   1,   2,   2,   
        6,   3,   5,   3,   3,   3,   6,   3,   3,   6,   6,   7,   
        6,   2,   6,   3,   3,   3,   7,   3,   4,   7,   7,   7, 
        
        6,   2,   3,   7,   2,   7,   2,   7,   2,   6,   4,   8,   
        5,   1,   3,   6,   1,   6,   2,   5,   1,   4,   4,   7,   
        3,   5,   6,   4,   6,   3,   5,   2,   5,   2,   7,   5,   
        2,   5,   7,   4,   6,   3,   6,   2,   6,   2,   9,   4, 
        
        3,   8,   2,   2,   2,   6,   2,   6,   2,   5,   3,   7,   
        2,   7,   2,   2,   2,   4,   2,   4,   1,   4,   2,   7,   
        8,   5,   5,   6,   5,   2,   5,   2,   4,   1,   6,   3,   
        7,   4,   5,   7,   6,   2,   4,   1,   6,   1,   7,   3, 
        
        3,   5,   8,   3,   6,   3,   8,   2,   7,   3,   9,   2,   
        4,   4,   6,   2,   5,   2,   7,   2,   9,   1,   6,   1,   
        7,   2,   4,   6,   3,   8,   5,   5,   6,   6,   5,   7,   
        5,   1,   4,   6,   2,   7,   6,   5,   7,   7,   3,   6, 
        
        7,   3,   8,   3,   8,   9,   4,   3,   7,   2,   7,   2,   
        7,   2,   6,   3,   7,   7,   3,   2,   5,   2,   6,   2,   
        4,   7,   5,   7,   5,   5,   6,   7,   3,   4,   3,   5,   
        4,   7,   4,   7,   4,   4,   8,   6,   3,   4,   3,   6] # the input of your IR values
        cellArray = []
        0.upto(@numberOfRows-1){|currentCell| # go from 0 through every column
            sumCount = 0
            sum = 0
            tmp = []
            currentCell.step(internalResistances.length-1, @numberOfRows){|i| # step throught internalResistances from the column to plus a row
                sumCount += 1
                tmp << internalResistances[i].to_f # add all the vaules per Row
                if sumCount == 4 # only capture 4 cells at a time though
                    sumCount = 0
                    cellArray << tmp # cell array will contain an array of 72 packs. Goes well with Peanut Butter and Raisins.
                    tmp = []
                end
            }
        }
        @dictionary = Marshal.load(Marshal.dump(cellArray)) # @dictionary stores an ordered copy of the packs for later retrieval
        order = @readIn.flatten.reverse
        0.upto(@cellsPerRow-1) {|i|
            @battery[i] = Array.new(@numberOfRows, 1)
            0.upto(@numberOfRows-1){ |x|
                @battery[i][x] = cellArray[(order.pop() - 1)] # pull pack values into the whole battery pack in an ordered array
            }        
        }
        @battery
    end
    
    def computeParallelResistance(who, index)# this function computes the resistance across a single row
        sum = 0.0
        who.each do |r|
            sum += 1/r[index] # standard parallel resistance stuff
        end
        return (1/sum)
    end
    def cost(who, who1, focus1, focus2) # changing this function will change the behavior of the optimization drastically
        tempVar, tempVar2 = [], []
        0.upto(3){|i|
            tempVar <<  computeParallelResistance(who[focus1], i) << computeParallelResistance(who[focus2], i) # for each subrow, append the new resistances to an array
            tempVar2 << computeParallelResistance(@battery[focus1], i) << computeParallelResistance(@battery[focus2], i) # and the old ones
        }
        gapsum, gapsum2 = 0, 0
        tempVar2.sort! # sort the arrays
        tempVar.sort!
        tempVar.each_with_index do |x, i| # traverse one array while spitting out indicies
            gapsum += (tempVar.reverse[i] - x).abs # sum the deltas between each set of farthest points
            gapsum2 += (tempVar2.reverse[i] - tempVar2[i]).abs
        end
        return (gapsum - gapsum2) # return the difference
    end
    def energy(who)
        tempVar = []
        who.each do |row|
            0.upto(3){|i|
               tempVar << computeParallelResistance(row, i)
            }
        end
        return tempVar.sort[-1] - tempVar.sort[0] # in a better state, the max and min are closer
    end
    def trade
        who = Marshal.load(Marshal.dump(@battery)) # copy our pack
        y1 = rand(@cellsPerRow)
        x1 = rand(@numberOfRows)
        y2 = rand(@cellsPerRow)
        x2 = rand(@numberOfRows)
        who[y1][x1], who[y2][x2] = who[y2][x2], who[y1][x1] #Make a single trade
        @battery = Marshal.load(Marshal.dump(who)) if Math::E**(-1*cost(who, @battery, y1, y2)/@systemTemp) > rand # accept trade if it is good enough
    end
    def readOut(starterBattery, starterEnergy, finishBattery, finishEnergy) # just some readout shit
        count = 0
        puts 'Origi.|Optim.'
        starterBattery.each_with_index do |row, i|
            sum = 0
            sum2 = 0
            puts '______________'
            0.upto(3){|index|
                tempVar, tempVar2 = computeParallelResistance(row, index), computeParallelResistance(finishBattery[i], index)
                puts ('|' + tempVar.round(2).to_s + '  |  ' + tempVar2.round(2).to_s + '|')
                sum += tempVar
                sum2 += tempVar2
            }
            count +=1
            puts '---------------', (sum.round(2).to_s + '  |  ' + sum2.round(2).to_s),''
        end
        puts 'Initial net gap:' + starterEnergy.round(4).to_s, 'Optimized net gap:' + finishEnergy.round(4).to_s,'Percent improvement:' + (100*(1-finishEnergy/starterEnergy)).round(4).to_s + '%'
        tempVar = 0
        print 'Take this and put it into the instance call: ['
        finishBattery.each do |row|
            print '['
            row.each do |cell|
                tempVar =  @dictionary.index(cell)
                print ((tempVar+1).to_s + ',')
                @dictionary[tempVar] = 0
            end
            print '],'
        end
         print ']'
        puts ''
    end
    def runSimulation
        count = 0.0
        a = Time.new()
        b = Time.new()
        progress = Thread.new {
            loop{
                sleep(0.5)
                b = Time.new()
                timeLeft = (((b-a)/count)*(@cycles-count)).round()
                puts "\e[H\e[2J #{timeLeft} seconds remaining" 
                
            }
        } # this just gives us a handy dandy timer
        
        spawnPack() # make a pack
        save = Marshal.load(Marshal.dump(@battery)) #store battery info to a nicer handle
        best = energy(save) # get initial state
        copyBattery, copyEnergy = Marshal.load(Marshal.dump(save)), energy(save) # just a copy to work with
        state = ''
        @cycles.downto(0){|i|
            count +=1.0
            trade()
            state = energy(@battery)
            best, save = state, Marshal.load(Marshal.dump(@battery)) unless best < state
            @systemTemp *= @decreaseRate
        }
        
        progress.kill # no more timer
        puts ''
        readOut(copyBattery, copyEnergy, save, energy(save))
        puts ((b-a)*1000).round(1).to_s + ' milliseconds ' + ((@cycles/(b-a))).round(1).to_s + ' cycles per second'
    end
end
start = [[43,58,10,22,23,41,1,68,14,36,33,28,],[66,3,46,21,39,52,12,38,25,15,5,30,],[59,13,20,8,48,2,34,63,53,11,60,49,],[56,42,65,9,16,17,67,7,31,50,29,26,],[72,37,32,4,18,47,71,45,44,51,6,35,],[57,24,40,55,69,19,54,62,27,64,70,61,],]


newpack = Pack.new(6, 12, 1000.0, 0.999, 0.00001, start)
#puts newpack.energy(newpack.spawnPack())
newpack.runSimulation()

