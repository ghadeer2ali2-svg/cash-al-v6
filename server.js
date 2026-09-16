const app=require('./api/index');
const port=process.env.PORT||3000;
app.listen(port,()=>console.log(`CASH AL v6 listening on ${port}`));
