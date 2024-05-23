% ----------------------------------------------------------------
% MATLAB Competition: Bus Distribution System
% ----------------------------------------------------------------
% In this second part of the project, we distribute buses to all routes
% based on the total number of students.
% 
% The script groups students taking the same bus at the same time,
% calculates the total number of students, and then distributes the buses 
% to all routes based on bus capacities.
%
% The user inputs the total number of buses and different bus sizes.
% The result of this code is to predict the total traffic of students 
% taking the bus every day and at different times, enabling a proper 
% distribution of buses and predicting the number of buses needed.
% 
% Note: Unregistered students are not considered in this distribution.
% ----------------------------------------------------------------

%------------------------------------------------------------
% Clear command window and workspace

clc;
clear;
%------------------------------------------------------------------------------------------------

%------------------------------------------------------------------------------------------------
% Load student data from JSON file

jsonData = fileread('students.json');
studentsCell = jsondecode(jsonData);

% Prompt user for bus capacities and total number of buses
prompt = {'Enter capacity of Big Bus:', 'Enter capacity of Medium Bus:', 'Enter capacity of Small Bus:', 'Enter total number of buses:'};
dlgtitle = 'Bus Capacities and Total Number of Buses';
dims = [1 35];
definput = {'131', '83', '60', '13'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

%------------------------------------------------------------------------------------------------

% Convert the input to numeric values
bigBusCapacity = str2double(answer{1});
mediumBusCapacity = str2double(answer{2});
smallBusCapacity = str2double(answer{3});
totalBuses = str2double(answer{4});

%-------------------------------------------------------------------------------------------------
% Define parameters
numStudents = length(studentsCell);
numRoutes = 8;
daysOfWeek = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
timeSlots = {'8:30', '9:30', '10:30', '11:30', '12:30', '13:30', '14:30', '15:30', '16:30', '17:30', '18:30', '19:30'};
validTimeSlots = cellfun(@(x) strrep(x, ':', '_'), timeSlots, 'UniformOutput', false);

%--------------------------------------------------------------------------------------------------
% Initialize route occupancy matrix for each route, day, and time slot
routeOccupancy = zeros(length(daysOfWeek), length(timeSlots), numRoutes);

%-------------------------------------------------------------------------------------------------
% Process student data
for i = 1:numStudents
    student = studentsCell(i);
    if student.isRegistered == 1
        timetable = student.timetable;
        route = student.route;
        for d = 1:length(daysOfWeek)
            for t = 1:length(timeSlots)
                if timetable.(daysOfWeek{d})(t) == 1 % Class at this time
                    routeOccupancy(d, t, route) = routeOccupancy(d, t, route) + 1;
                end
            end
        end
    end
end

%------------------------------------------------------------------------------------------------
% Define bus capacities and names
busCapacities = [bigBusCapacity, mediumBusCapacity, smallBusCapacity];
busNames = {'Big Bus', 'Medium Bus', 'Small Bus'};
busList = randsample(busCapacities, totalBuses, true);
busNameList = arrayfun(@(x) busNames{find(busCapacities == x, 1)}, busList, 'UniformOutput', false);

%-----------------------------------------------------------------------------------------------
% Initialize number of buses needed for each route, day, and time slot
numBuses = cell(length(daysOfWeek), length(timeSlots), numRoutes);

%-----------------------------------------------------------------------------------------------
% Initialize a matrix to keep track of used buses
usedBuses = zeros(length(daysOfWeek), length(timeSlots));

for d = 1:length(daysOfWeek)
    for t = 1:length(timeSlots)
        remainingBuses = busList;
        remainingBusNames = busNameList;
        totalBusesUsed = 0;
        
        for r = 1:numRoutes
            totalStudentsOnRoute = routeOccupancy(d, t, r);
            remainingStudents = totalStudentsOnRoute;
            busesAssigned = {};
            
            % Assign buses until all students are accommodated or we run out of buses
            while remainingStudents > 0 && totalBusesUsed < totalBuses
                if isempty(remainingBuses)
                    break;
                end
                
                currentBusCapacity = remainingBuses(1);
                currentBusName = remainingBusNames{1};
                busesAssigned = [busesAssigned, currentBusName];
                remainingStudents = remainingStudents - currentBusCapacity;
                remainingBuses(1) = []; % Remove assigned bus from the list
                remainingBusNames(1) = []; % Remove assigned bus name from the list
                totalBusesUsed = totalBusesUsed + 1;
            end
            
            % If there are still remaining students and no buses left, 
            % use any available buses to accommodate them
            if remainingStudents > 0 && totalBusesUsed < totalBuses
                while remainingStudents > 0 && totalBusesUsed < totalBuses
                    additionalBusCapacity = busList(1); % Use the first bus capacity as default
                    additionalBusName = busNameList{1};
                    busesAssigned = [busesAssigned, additionalBusName];
                    remainingStudents = remainingStudents - additionalBusCapacity;
                    totalBusesUsed = totalBusesUsed + 1;
                end
            end
            
            % Store the number of buses assigned
            numBuses{d, t, r} = busesAssigned;
            usedBuses(d, t) = usedBuses(d, t) + length(busesAssigned);
        end
    end
end

%--------------------------------------------------------------------------------------------------
% Ensure total buses used do not exceed available buses
for d = 1:length(daysOfWeek)
    for t = 1:length(timeSlots)
        if usedBuses(d, t) > totalBuses
            fprintf('Warning: On %s at %s, total buses used (%d) exceeds available buses (%d)\n', ...
                    daysOfWeek{d}, timeSlots{t}, usedBuses(d, t), totalBuses);
        end
    end
end

%-------------------------------------------------------------------------------------------------
% Display the number of students and buses needed for each route, day, and time slot
disp('Number of Students and Buses Needed for Each Route, Day, and Time Slot:');
for d = 1:length(daysOfWeek)
    fprintf('%s:\n', daysOfWeek{d});
    for t = 1:length(timeSlots)
        fprintf('  %s:\n', timeSlots{t});
        for r = 1:numRoutes
            totalStudentsOnRoute = routeOccupancy(d, t, r);
            busesNeeded = numBuses{d, t, r};
            busCount = struct('Big', 0, 'Medium', 0, 'Small', 0);
            for b = 1:length(busesNeeded)
                switch busesNeeded{b}
                    case 'Big Bus'
                        busCount.Big = busCount.Big + 1;
                    case 'Medium Bus'
                        busCount.Medium = busCount.Medium + 1;
                    case 'Small Bus'
                        busCount.Small = busCount.Small + 1;
                end
            end
            fprintf('    Route %d: %d students, %d buses [', r, totalStudentsOnRoute, length(busesNeeded));
            if busCount.Big > 0
                fprintf('%d Big Buses', busCount.Big);
            end
            if busCount.Medium > 0
                if busCount.Big > 0
                    fprintf(', ');
                end
                fprintf('%d Medium Buses', busCount.Medium);
            end
            if busCount.Small > 0
                if busCount.Big > 0 || busCount.Medium > 0
                    fprintf(', ');
                end
                fprintf('%d Small Buses', busCount.Small);
            end
            fprintf(']\n');
        end
    end
end
