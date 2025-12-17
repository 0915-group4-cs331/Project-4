CREATE   FUNCTION ClassSchedule.fn_BuildingLocation_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        BuildingCode =
            CASE
                WHEN CHARINDEX(' ', Location) > 0
                    THEN LEFT(Location, CHARINDEX(' ', Location) - 1)
                ELSE Location
            END,
        CampusName   = 'Queens College'
    FROM Uploadfile.CurrentSemesterCourseOfferings
    WHERE Location IS NOT NULL
);

CREATE   FUNCTION ClassSchedule.fn_Class_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT
        CourseID,
        MIN(InstructorID) AS InstructorID,
        MIN(ModeOfInstructionID) AS ModeOfInstructionID,
        MIN(RoomID) AS RoomID,
        Semester,
        Section,
        MIN(MeetingDays) AS MeetingDays,
        MIN(Enrolled) AS Enrolled,
        MIN(EnrollmentLimit) AS EnrollmentLimit,
        MIN(StartTime) AS StartTime,
        MIN(EndTime) AS EndTime
    FROM
    (
        SELECT DISTINCT
            c.CourseID,
            i.InstructorID,
            m.ModeOfInstructionID,
            r.RoomID,
            u.Semester,
            u.Sec AS Section,
            u.Day AS MeetingDays,
            u.Enrolled,
            u.Limit AS EnrollmentLimit,
            LTRIM(RTRIM(LEFT(u.Time, CHARINDEX('-', u.Time) - 1))) AS StartTime,
            LTRIM(RTRIM(SUBSTRING(u.Time, CHARINDEX('-', u.Time) + 1, 20))) AS EndTime
        FROM Uploadfile.CurrentSemesterCourseOfferings u
        JOIN ClassSchedule.Course c
            ON c.CourseCode = LEFT(u.[Course (hr, crd)], CHARINDEX('(', u.[Course (hr, crd)]) - 2)
        JOIN ClassSchedule.Instructor i
            ON i.LastName = PARSENAME(REPLACE(u.Instructor, ', ', '.'), 2)
           AND i.FirstName = PARSENAME(REPLACE(u.Instructor, ', ', '.'), 1)
        JOIN ClassSchedule.ModeOfInstruction m
            ON m.ModeName = u.[Mode of Instruction]
        LEFT JOIN ClassSchedule.Room r
            ON r.RoomNumber = LTRIM(RTRIM(SUBSTRING(u.Location, CHARINDEX(' ', u.Location) + 1, LEN(u.Location))))
        WHERE u.[Course (hr, crd)] IS NOT NULL
          AND u.Time IS NOT NULL
    ) AS src
    GROUP BY Semester, Section, CourseID
);

CREATE   FUNCTION ClassSchedule.fn_Course_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        d.DepartmentID,

        CourseCode =
            LEFT(
                u.[Course (hr, crd)],
                CHARINDEX('(', u.[Course (hr, crd)]) - 2
            ),

        CourseName = u.Description,

        CourseHours =
            ISNULL(
                TRY_CAST(
                    SUBSTRING(
                        u.[Course (hr, crd)],
                        CHARINDEX('(', u.[Course (hr, crd)]) + 1,
                        CHARINDEX(',', u.[Course (hr, crd)])
                          - CHARINDEX('(', u.[Course (hr, crd)]) - 1
                    ) AS DECIMAL(4,2)
                ), 0
            ),

        CourseCredits =
            ISNULL(
                TRY_CAST(
                    SUBSTRING(
                        u.[Course (hr, crd)],
                        CHARINDEX(',', u.[Course (hr, crd)]) + 1,
                        CHARINDEX(')', u.[Course (hr, crd)])
                          - CHARINDEX(',', u.[Course (hr, crd)]) - 1
                    ) AS DECIMAL(4,2)
                ), 0
            )

    FROM Uploadfile.CurrentSemesterCourseOfferings u
    JOIN ClassSchedule.Department d
        ON d.DepartmentCode =
           LEFT(u.[Course (hr, crd)],
                CHARINDEX(' ', u.[Course (hr, crd)]) - 1)
    WHERE u.[Course (hr, crd)] IS NOT NULL
      AND CHARINDEX('(', u.[Course (hr, crd)]) > 0
      AND CHARINDEX(',', u.[Course (hr, crd)]) > 0
      AND CHARINDEX(')', u.[Course (hr, crd)]) > 0
);

CREATE FUNCTION ClassSchedule.fn_Department_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        DepartmentCode = LEFT([Course (hr, crd)], CHARINDEX(' ', [Course (hr, crd)]) - 1)
    FROM Uploadfile.CurrentSemesterCourseOfferings
);

CREATE   FUNCTION ClassSchedule.fn_Instructor_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        FirstName = LTRIM(RTRIM(
            SUBSTRING(
                Instructor,
                CHARINDEX(',', Instructor) + 1,
                LEN(Instructor)
            )
        )),
        LastName = LTRIM(RTRIM(
            LEFT(
                Instructor,
                CHARINDEX(',', Instructor) - 1
            )
        ))
    FROM Uploadfile.CurrentSemesterCourseOfferings
    WHERE Instructor IS NOT NULL
      AND CHARINDEX(',', Instructor) > 0
);

CREATE FUNCTION ClassSchedule.fn_InstructorDepartment_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        i.InstructorID,
        d.DepartmentID
    FROM Uploadfile.CurrentSemesterCourseOfferings u
    JOIN ClassSchedule.Instructor i
        ON i.LastName = PARSENAME(REPLACE(u.Instructor, ', ', '.'), 2)
       AND i.FirstName = PARSENAME(REPLACE(u.Instructor, ', ', '.'), 1)
    JOIN ClassSchedule.Department d
        ON d.DepartmentCode =
           LEFT(u.[Course (hr, crd)], CHARINDEX(' ', u.[Course (hr, crd)]) - 1)
);

CREATE FUNCTION ClassSchedule.fn_ModeOfInstruction_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        ModeName = [Mode of Instruction],
        IsOnline = CASE WHEN [Mode of Instruction] LIKE '%Online%' THEN 1 ELSE 0 END,
        IsHybrid = CASE WHEN [Mode of Instruction] LIKE '%Hybrid%' OR [Mode of Instruction] LIKE '%Web-Enhanced%' THEN 1 ELSE 0 END,
        IsSynchronous = 0,
        IsOnCampusRequired =
            CASE WHEN [Mode of Instruction] LIKE '%In-Person%' THEN 1 ELSE 0 END
    FROM Uploadfile.CurrentSemesterCourseOfferings
);

CREATE   FUNCTION ClassSchedule.fn_Room_Source()
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        bl.BuildingLocationID,
        RoomNumber = LTRIM(RTRIM(x.Room))
    FROM Uploadfile.CurrentSemesterCourseOfferings u
    CROSS APPLY (
        SELECT
            SpacePos = CHARINDEX(' ', u.Location)
    ) p
    CROSS APPLY (
        SELECT
            BuildingCode = LEFT(u.Location, p.SpacePos - 1),
            Room = SUBSTRING(u.Location, p.SpacePos + 1, LEN(u.Location))
    ) x
    JOIN ClassSchedule.BuildingLocation bl
        ON bl.BuildingCode = x.BuildingCode
    WHERE u.Location IS NOT NULL
      AND p.SpacePos > 0
);

CREATE PROCEDURE ClassSchedule.LoadQueensCourseSchedule
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC ClassSchedule.usp_LoadBuildingLocation @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadRoom @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadDepartment @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadInstructor @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadInstructorDepartment @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadModeOfInstruction @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadCourse @UserAuthorizationKey;
    EXEC ClassSchedule.usp_LoadClass @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadBuildingLocation
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.BuildingLocation
        (BuildingCode, CampusName, UserAuthorizationKey)
    SELECT
        BuildingCode,
        CampusName,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_BuildingLocation_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.BuildingLocation',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE   PROCEDURE ClassSchedule.usp_LoadClass
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.Class
    (
        CourseID,
        InstructorID,
        ModeOfInstructionID,
        RoomID,
        Semester,
        [Section],
        MeetingDays,
        Enrolled,
        EnrollmentLimit,
        StartTime,
        EndTime
    )
    SELECT
        cs.CourseID,
        cs.InstructorID,
        cs.ModeOfInstructionID,
        cs.RoomID,
        cs.Semester,
        cs.Section,
        cs.MeetingDays,
        cs.Enrolled,
        cs.EnrollmentLimit,
        cs.StartTime,
        cs.EndTime
    FROM
        ClassSchedule.fn_Class_Source() cs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ClassSchedule.Class c
        WHERE c.Semester = cs.Semester
          AND c.CourseID = cs.CourseID
          AND c.Section = cs.Section
    );

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.Class',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadCourse
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.Course
        (DepartmentID, CourseCode, CourseName, CourseHours, CourseCredits, UserAuthorizationKey)
    SELECT
        DepartmentID,
        CourseCode,
        CourseName,
        CourseHours,
        CourseCredits,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_Course_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.Course',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadDepartment
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.Department
        (DepartmentCode, UserAuthorizationKey)
    SELECT
        DepartmentCode,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_Department_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.Department',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadInstructor
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.Instructor
        (FirstName, LastName, UserAuthorizationKey)
    SELECT
        FirstName,
        LastName,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_Instructor_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.Instructor',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadInstructorDepartment
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.InstructorDepartment
        (InstructorID, DepartmentID, UserAuthorizationKey)
    SELECT
        InstructorID,
        DepartmentID,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_InstructorDepartment_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.InstructorDepartment',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE   PROCEDURE ClassSchedule.usp_LoadModeOfInstruction
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.ModeOfInstruction
        (ModeName, IsOnline, IsHybrid, IsOnCampusRequired, UserAuthorizationKey)
    SELECT
        s.ModeName,
        s.IsOnline,
        s.IsHybrid,
        s.IsOnCampusRequired,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_ModeOfInstruction_Source() s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ClassSchedule.ModeOfInstruction t
        WHERE t.ModeName = s.ModeName
    );

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.ModeOfInstruction',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;

CREATE PROCEDURE ClassSchedule.usp_LoadRoom
    @UserAuthorizationKey INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();

    INSERT INTO ClassSchedule.Room
        (BuildingLocationID, RoomNumber, UserAuthorizationKey)
    SELECT
        BuildingLocationID,
        RoomNumber,
        @UserAuthorizationKey
    FROM ClassSchedule.fn_Room_Source();

    EXEC Process.usp_TrackWorkflow
        @StartTime,
        'Load ClassSchedule.Room',
        @@ROWCOUNT,
        @UserAuthorizationKey;
END;