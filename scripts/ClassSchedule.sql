-- DROP SCHEMA ClassSchedule;

CREATE SCHEMA ClassSchedule;
-- QueensClassScheduleThisCurrentSemester.ClassSchedule.BuildingLocation definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.BuildingLocation;

CREATE TABLE BuildingLocation (
	BuildingLocationID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	BuildingCode BuildingCode COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CampusName CampusName COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NOT NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_BuildingLocation_BuildingLocationID PRIMARY KEY (BuildingLocationID)
);
CREATE UNIQUE NONCLUSTERED INDEX IX_BuildingLocation_CampusName_BuildingCode ON QueensClassScheduleThisCurrentSemester.ClassSchedule.BuildingLocation (CampusName, BuildingCode);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.Department definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.Department;

CREATE TABLE Department (
	DepartmentID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	DepartmentCode DepartmentCode COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NOT NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_Department_DepartmentID PRIMARY KEY (DepartmentID)
);
CREATE UNIQUE NONCLUSTERED INDEX AK_Department_DepartmentCode ON QueensClassScheduleThisCurrentSemester.ClassSchedule.Department (DepartmentCode);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.Instructor definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.Instructor;

CREATE TABLE Instructor (
	InstructorID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	FirstName FirstName COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	LastName LastName COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NOT NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_Instructor_InstructorID PRIMARY KEY (InstructorID)
);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.ModeOfInstruction definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.ModeOfInstruction;

CREATE TABLE ModeOfInstruction (
	ModeOfInstructionID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	ModeName ModeName COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsOnline IsFlag NOT NULL,
	IsHybrid IsFlag NOT NULL,
	IsOnCampusRequired IsFlag NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_ModeOfInstruction_ModeOfInstructionID PRIMARY KEY (ModeOfInstructionID)
);
CREATE UNIQUE NONCLUSTERED INDEX AK_ModeOfInstruction_ModeName ON QueensClassScheduleThisCurrentSemester.ClassSchedule.ModeOfInstruction (ModeName);
ALTER TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.ModeOfInstruction WITH NOCHECK ADD CONSTRAINT CK_ModeOfInstruction_ModeName CHECK ((len([ModeName])>(0)));


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.Course definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.Course;

CREATE TABLE Course (
	CourseID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	DepartmentID uniqueidentifier NOT NULL,
	CourseCode varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CourseName varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CourseHours CourseHour NOT NULL,
	CourseCredits CourseCredit NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NOT NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_ClassSchedule_CourseID PRIMARY KEY (CourseID),
	CONSTRAINT FK_Course_Department_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);
CREATE UNIQUE NONCLUSTERED INDEX IX_Course_CourseName_CourseCode ON QueensClassScheduleThisCurrentSemester.ClassSchedule.Course (CourseName, CourseCode);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.InstructorDepartment definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.InstructorDepartment;

CREATE TABLE InstructorDepartment (
	InstructorDepartmentID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	InstructorID SurrogateKeyInt NOT NULL,
	DepartmentID SurrogateKeyInt NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_InstructorDepartment_InstructorDepartmentID PRIMARY KEY (InstructorDepartmentID),
	CONSTRAINT FK_InstructorDepartment_Department_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID),
	CONSTRAINT FK_InstructorDepartment_Instructor_InstructorID FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
);
CREATE UNIQUE NONCLUSTERED INDEX IX_InstructorDepartment_InstructorID_DepartmentID ON QueensClassScheduleThisCurrentSemester.ClassSchedule.InstructorDepartment (InstructorID, DepartmentID);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.Room definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.Room;

CREATE TABLE Room (
	RoomID SurrogateKeyInt IDENTITY(1,1) NOT NULL,
	BuildingLocationID SurrogateKeyInt NOT NULL,
	RoomNumber RoomNumber COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	UserAuthorizationKey SurrogateKeyInt NULL,
	DateAdded DateAdded DEFAULT sysdatetime() NOT NULL,
	DateOfLastUpdate DateOfLastUpdate DEFAULT sysdatetime() NOT NULL,
	CONSTRAINT PK_Room_RoomID PRIMARY KEY (RoomID),
	CONSTRAINT FK_Room_BuildingLocation_BuildingLocationID FOREIGN KEY (BuildingLocationID) REFERENCES BuildingLocation(BuildingLocationID)
);
CREATE UNIQUE NONCLUSTERED INDEX IX_Room_BuildingLocationID_RoomNumber ON QueensClassScheduleThisCurrentSemester.ClassSchedule.Room (BuildingLocationID, RoomNumber);


-- QueensClassScheduleThisCurrentSemester.ClassSchedule.Class definition

-- Drop table

-- DROP TABLE QueensClassScheduleThisCurrentSemester.ClassSchedule.Class;

CREATE TABLE Class (
	ClassID SurrogateKeyInt IDENTITY(100,1) NOT NULL,
	CourseID SurrogateKeyInt NOT NULL,
	InstructorID SurrogateKeyInt NOT NULL,
	ModeOfInstructionID SurrogateKeyInt NOT NULL,
	RoomID SurrogateKeyInt NULL,
	Semester Semester COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Section] Section COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MeetingDays MeetingDays COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Enrolled Enrolled NOT NULL,
	EnrollmentLimit EnrollmentLimit NULL,
	StartTime ClassTime COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	EndTime ClassTime COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CONSTRAINT AK_Class_Semester_CourseID_Section UNIQUE (Semester,CourseID,[Section]),
	CONSTRAINT PK_Class_ClassID PRIMARY KEY (ClassID),
	CONSTRAINT FK_Class_Course_CourseID FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
	CONSTRAINT FK_Class_Instructor_InstructorID FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
	CONSTRAINT FK_Class_ModeOfInstruction_ModeOfInstructionID FOREIGN KEY (ModeOfInstructionID) REFERENCES ModeOfInstruction(ModeOfInstructionID),
	CONSTRAINT FK_Class_Room_RoomID FOREIGN KEY (RoomID) REFERENCES Room(RoomID)
);
CREATE NONCLUSTERED INDEX IX_Class_StartTime_EndTime ON QueensClassScheduleThisCurrentSemester.ClassSchedule.Class (StartTime, EndTime);