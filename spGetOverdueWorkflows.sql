CREATE PROCEDURE [dbo].[spGetOverdueWorkflows] @daysago int
AS   
BEGIN
	Select RequestWorkflows.ID, RequestWorkflows.RequestID, RequestWorkflows.State, RequestWorkflows.StatusID, URLKey, 
	 RequestedTimeStamp, LastReminderSent, States.CoordinatorEmail, States.Website, RequestingState.State
	From RequestWorkflows 
	INNER JOIN States on RequestWorkflows.State = States.State
	INNER JOIN Requests on RequestWorkflows.RequestID = Requests.ID
	INNER JOIN States RequestingState on RequestingState.StateAbbreviation = Requests.State
	Where 
	Requests.StatusID = 1 AND
	RequestWorkflows.StatusID = 1 AND 
	DATEDIFF(day, RequestedTimeStamp, GETDATE()) >= @daysago AND
	(LastReminderSent is null OR DATEDIFF(day, LastReminderSent, GETDATE()) >= @daysago)

END;