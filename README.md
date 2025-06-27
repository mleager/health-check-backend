# Health Check Backend 

![backend-health-check-down](https://github.com/user-attachments/assets/6fa50166-f0e8-4fb4-8bad-cef0038b47eb)


![backend-health-check-up](https://github.com/user-attachments/assets/d55604f2-3487-44e8-8b49-2063ba144418)

Provide a `/health` endpoint that allows access from other servers through CORS.

Default Port is 4000, but can be changed by setting a local `PORT` var:

- $ export PORT=4080

Health Check Returns:

- FrontendStatus
- Uptime
- Timestamp
- CommitHash

Was going to implement a periodic check, but seemed unnecessary for this scenario  
Left it in, in case I decide to iterate on it another time


