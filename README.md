# Health Check Backend 

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

