<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@page session="false" %>

<%@page import="java.io.PrintWriter"%><html>
<%@page import="javax.sql.DataSource"%>
<%@page import="java.sql.Statement"%>
<%@page import="jakarta.jms.ConnectionFactory"%>
<%@page import="jakarta.jms.Session"%>
<%@page import="jakarta.jms.Queue"%>
<%@page import="jakarta.jms.MessageProducer"%>
<%@page import="jakarta.jms.MessageConsumer"%>
<%@page import="jakarta.jms.Message"%>
<%@page import="jakarta.jms.TextMessage"%>
<%@page import="jakartadummyrm.DummyXAResource" %>
<%@page import="jakartadummyrm.DummyXAUtil" %>

<head>
	<title>MQ-DB Execute</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
<h2>RM1=MQ, RM2=DB(1)</h2>

<%@include file="CommonHeader.jsp"%>
<%@include file="DummyRMOutput.jsp"%>
<% out.flush(); %>

<hr>
<pre>
<%
	try {
	
		// Start Transaction
		UserTransaction ut = lookupUserTransaction();
		ut.begin();
	
		// Dummy RM 1 - enlist
		DummyXAUtil.enlist( "dummy1", sleepPosition1, sleepDuration1 * 1000 );
		
		//---------------------------------------------------------------------
		// MQ
		//---------------------------------------------------------------------
		ConnectionFactory cf = lookupConnectionFactory();
		Queue q = lookupQueue();
		jakarta.jms.Connection mqcon = cf.createConnection();
		mqcon.start();	
		Session ses = mqcon.createSession( false, Session.AUTO_ACKNOWLEDGE );
		MessageProducer sender = ses.createProducer( q );
		String msgStr = "2PC TEST: MQ-DB";
		TextMessage txtMsg = ses.createTextMessage( msgStr );
		sender.send( txtMsg );
		sender.close();
		ses.close();
		mqcon.close();
		
		// Dummy RM 2 - enlist
		DummyXAUtil.enlist( "dummy2", sleepPosition2, sleepDuration2 * 1000 );
		
		//---------------------------------------------------------------------
		// DB 
		//---------------------------------------------------------------------
		String sql1 = "INSERT INTO TESTTBL VALUES( CURRENT TIMESTAMP, \'2PC TEST: MQ-DB\' )";
		DataSource ds1 = lookupDataSource1();
		java.sql.Connection dbcon1 = ds1.getConnection();
		Statement st1 = dbcon1.createStatement();
		st1.executeUpdate( sql1 );
		st1.close();
		dbcon1.close();

		// Dummy RM 3 - enlist
		DummyXAUtil.enlist( "dummy3", sleepPosition3, sleepDuration3 * 1000 );
		
		// Commit Transaction
		ut.commit();
		
	} catch ( Exception e ) {
		out.println( e.getMessage() );
		PrintWriter pw = new PrintWriter( out );
		e.printStackTrace( pw );
		pw.flush();
	}

%>
</pre>

<p>
<hr>
<a href="index.html">Home</a>

</body>
</html>
