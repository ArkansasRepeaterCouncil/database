CREATE TABLE [dbo].[RepeaterTypes](      [ID] [TINYINT] NOT NULL IDENTITY(1,1)    , [Type] [VARCHAR](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL  
	    , CONSTRAINT [PK_RepeaterTypes] PRIMARY KEY CLUSTERED ([ID]));