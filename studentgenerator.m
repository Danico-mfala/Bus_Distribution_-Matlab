% ----------------------------------------------------------------
% MATLAB Competition: Bus Distribution System
% ----------------------------------------------------------------
% This script generates student data for a university, including:
% - Registration status
% - Assigned bus route
% - Weekly class timetable
%
% The total number of students is provided by the user.
% The generated data is saved in a JSON file.
% The script also plots the information for the first 3 students 
% to demonstrate the random generation.
%
% The JSON file will be used as a database for the next task, 
% which involves generating the bus distribution based on days, times, and hours.
% ----------------------------------------------------------------


% Define parameters

clc;
clear;

% Input dialog to enter the total number of students
prompt = {'Enter the total number of students:'};
dlgtitle = 'Input';
dims = [1 35];
definput = {'100'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

% ----------------------------------------------------------------
% Convert the input to a number

numStudents = str2double(answer{1});

numRegistered = round(numStudents * 0.5); % Number of registered students (adjustable)
numUnregistered = numStudents - numRegistered;
numRoutes = 8; % Total number of routes

daysOfWeek = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
timeSlots = {'8:30', '9:30', '10:30', '11:30', '12:30', '13:30', '14:30', '15:30', '16:30', '17:30', '18:30', '19:30'};

% ----------------------------------------------------------------
% Replace colon character in time slots with underscore
validTimeSlots = cellfun(@(x) strrep(x, ':', '_'), timeSlots, 'UniformOutput', false);

% ----------------------------------------------------------------
% Generate student data
students = cell(1, numStudents);
for i = 1:numStudents
    student.ID = i;
    if i <= numRegistered
        student.isRegistered = 1; % Registered
    else
        student.isRegistered = 0; % Not registered
    end
    
    % Assign a random route number (1 to numRoutes)
    student.route = randi([1, numRoutes]);
    
    % Generate a random timetable for the student
    timetable = struct();
    for day = daysOfWeek
        timetable.(day{1}) = randi([0, 1], 1, length(timeSlots)); % 0: no class, 1: class
    end
    student.timetable = timetable;
    
    % Store the student structure in the cell array
    students{i} = student; % Append student to the array
end

% ----------------------------------------------------------------
% Convert the cell array of structures to JSON format
jsonData = jsonencode(students);

% Write JSON data to a file
fid = fopen('students.json', 'w');
if fid == -1
    error('Cannot create JSON file');
end
fwrite(fid, jsonData, 'char');
fclose(fid);

disp('JSON file "students.json" created successfully');

% ----------------------------------------------------------------
% Display the timetable and info for the first 3 students
for i = 1:min(3, numStudents)
    student = students{i};
    figure;
    % Create a timetable matrix for visualization
    timetableMatrix = zeros(length(daysOfWeek), length(timeSlots));
    for dayIdx = 1:length(daysOfWeek)
        day = daysOfWeek{dayIdx};
        timetableMatrix(dayIdx, :) = student.timetable.(day);
    end
    % Display student information
    subplot(3, 1, 1);
    title(sprintf('Student ID: %d\nRegistered: %d\nRoute: %d', ...
        student.ID, student.isRegistered, student.route));
    axis off;
    
    % Display the timetable
    subplot(3, 1, [2, 3]);
    imagesc(timetableMatrix);
    colormap(gray);
    colorbar;
    set(gca, 'XTick', 1:length(timeSlots), 'XTickLabel', timeSlots, ...
        'YTick', 1:length(daysOfWeek), 'YTickLabel', daysOfWeek);
    xlabel('Time Slots');
    ylabel('Days of Week');
    title(sprintf('Timetable for Student ID: %d', student.ID));
end
