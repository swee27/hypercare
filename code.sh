work_dir="/opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE"
cd $work_dir

cp /dev/null status.txt
cp /dev/null lbstatus.txt
cp /dev/null status.html

aws ecs list-services --cluster digitalx-prod-ecs-mas --region eu-west-1 > MSlist.txt
sed -i 's/\"//g; s/,//g' MSlist.txt
grep dal MSlist.txt|grep -vE 'combi|youth|sip|enterprise|escatalog|datadog|Fargate'|awk -F '/' '{print $NF}' > service.txt
while read serv
do
        cont=`echo $serv|awk -F '-EcsService' '{print $1}'`
        run_stat=`aws ecs describe-services --service $serv --cluster digitalx-prod-ecs-mas --region eu-west-1 --query 'services[*].deployments[*].[desiredCount,pendingCount,runningCount]' --output text`
        echo "$cont $run_stat" >> status.txt
done < service.txt

funstatchk()
{
        serv=$1
        [[ $serv = voxi ]] && { inst_state=`aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:175616551101:targetgroup/voxi-live-sqpx-tg-80/c33f681f3313012c --region eu-west-1 --query 'TargetHealthDescriptions[*].[TargetHealth.State]' --output text|sort|uniq`; } || { inst_state=`aws elb describe-instance-health --load-balancer-name digitalx-prod-elb-${serv} --region eu-west-1 --query 'InstanceStates[*].[State]' --output text|sort|uniq`; }
        grep -Eq 'OutOfService|unhealthy' <<< $inst_state && { echo "$serv OutOfService" >> lbstatus.txt; } || { echo "$serv InService" >> lbstatus.txt; }

}

echo "Checking sqpx servers"
funstatchk voxi
echo "Checking wcd servers"
funstatchk wcd
echo "Checking wsd servers"
funstatchk wsd
echo "Checking opx servers"
funstatchk opx

flnm=`aws s3 ls  digitalx-prod-order-report/Hourly --region=eu-west-1 --recursive|sort -k1,2|tail -1|awk  '{print $NF}'`
aws s3 cp s3://digitalx-prod-order-report/${flnm} /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv
sed -i '/SUBMITTED/ !d' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv
#order_cnt=`awk 'END{print NR -1}' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv`
#apple_cnt=`grep -Ei 'Apple iPhone SE' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
voxi_cnt=`grep -Ei 'YOUTH' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
reinvent_cnt=`grep -Ei 'WCS' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
samsungw3_cnt=`grep -Ei 'Samsung Galaxy Watch3' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
samsungn20_cnt=`grep -Ei 'Samsung Galaxy Note20 5G' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
samsungn20u_cnt=`grep -Ei 'Samsung Galaxy Note20 Ultra 5G' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
samsungts7_cnt=`grep -Ei 'Samsung Galaxy Tab S7 4G' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
samsungts7p_cnt=`grep -Ei 'Samsung Galaxy Tab S7+ 5G' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/MAIL/HYPERCARE/order-report.csv|wc -l`
chmod 777 order-report.csv


{
echo "<table border=1 WIDTH=50%>
<font color=BLUE>
<tr>
<td colspan=2><DOCTYPE html><html><head><body>
<h1 style='background-size: 100%;
color: #FFFFFF;
border: 5px solid #1C6EA4;
background: #232323;
background-size: 60%;
color: #FFFFFF;
border: 5px solid #1C6EA4;
background: #232323;
font-family: cursive, sans-serif;font-size: 48px;
letter-spacing: 2px;
word-spacing: 2px;
font-weight: normal;
text-shadow: 0 0 5px #FFF, 0 0 10px #FFF, 0 0 15px #FFF, 0 0 20px #49ff18, 0 0 30px #49FF18, 0 0 40px #49FF18, 0 0 55px #49FF18, 0 0 75px #49ff18;
text-decoration: none solid rgb(68, 68, 68);
text-align: center;
font-style: normal;
font-variant: normal;
text-transform: none;
background-size: 100%;
color: #FFFFFF;
border: 5px solid #1C6EA4;
background: #232323;'>
Digital X Report </h1>
</body></head></html></td></tr>
<tr><td rowspan=2 align="center">"VOXI/Reinvent Status : GREEN"</td>
<td align="center">"Reinvent orders so far: ${reinvent_cnt}"</td></tr>
<tr><td align="center">"VOXI orders so far: ${voxi_cnt}"</td></tr>
<tr><td rowspan=5 align="center">"Samsung orders so far"</td>
<td align="center">"Samsung Galaxy Watch3: ${samsungw3_cnt}"</td></tr>
<tr><td align="center">"Samsung Galaxy Note20 5G: ${samsungn20_cnt}"</td></tr>
<tr><td align="center">"Samsung Galaxy Note20 Ultra 5G: ${samsungn20u_cnt}"</td></tr>
<tr><td align="center">"Samsung Galaxy Tab S7 4G: ${samsungts7_cnt}"</td></tr>
<tr><td align="center">"Samsung Galaxy Tab S7+ 5G: ${samsungts7p_cnt}"</td></tr>
</font>
</table>"
echo "<table border=1 WIDTH=50%>"
echo "<font color=BLUE>"
echo "<tr>"
echo "<th WIDTH=20%>Microservice</th>"
echo "<th WIDTH=10%>Desired</th>"
echo "<th WIDTH=10%>Pending</th>"
echo "<th WIDTH=10%>Running</th>"
echo "</tr>"
echo "</font>"
while read ms des pen run
do
  if [ $des -eq $run ]
  then
    echo "<font color=GREEN>"
    echo "<td>$ms</td>"
    echo "<td align="center">$des</td>"
    echo "<td align="center">$pen</td>"
    echo "<td align="center">$run</td>"
echo "</tr>"
echo "</font>"
  else
    echo "<font color=RED>"
    echo "<td>$ms</td>"
    echo "<td align="center">$des</td>"
    echo "<td align="center">$pen</td>"
    echo "<td align="center">$run</td>"
echo "</tr>"
echo "</font>"
  fi
done < status.txt
echo "</table>"

echo "<table border=1 WIDTH=50%>"
echo "<font color=BLUE>"
echo "<tr>"
echo "<th WIDTH=25%>LoadBalancer</th>"
echo "<th WIDTH=25%>Status</th>"
echo "</tr>"
echo "</font>"
while read lb state
do
  if [ $state = "InService" ]
  then
    echo "<font color=GREEN>"
    echo "<td align="center">$lb</td>"
    echo "<td align="center">$state</td>"
echo "</tr>"
echo "</font>"
  else
    echo "<font color=RED>"
    echo "<td align="center">$lb</td>"
    echo "<td align="center">$state</td>"
echo "</tr>"
echo "</font>"
  fi
done < lbstatus.txt
echo "</table>"
echo "</body></html>"
} >> status.html
chmod 777 status.html
SENDMAIL_BIN='/usr/sbin/sendmail'
FROM_MAIL_ADDRESS="DigitalX-L2@vodafone.tssc"
FROM_MAIL_DISLAY="DigitalX-L2@vodafone.tssc"
RECIPIENT_ADDRESSES="sweekruti.kayarkar@vodafone.com"
#RECIPIENT_ADDRESSES="DL-TSSC-AO2-UK-Online-Support@vodafone.com Alex.Battersby@vodafone.com DL-TSSC-CCS-CM_L2_Team@vodafone.com"
#RECIPIENT_ADDRESSES="DL-TSSC-AO2-UK-Online-Support@vodafone.com Alex.Battersby@vodafone.com"

MAIL_CMD=("$SENDMAIL_BIN" -f "$FROM_MAIL_DISLAY" -F "$FROM_MAIL_ADDRESS" "$RECIPIENT_ADDRESSES")
(echo "Subject: Digital-X Hypercare Report";echo "To: $RECIPIENT_ADDRESSES";echo -e "MIME-Version: 1.0\nContent-Type: text/html\n\n" && cat status.html) | "${MAIL_CMD[@]}"

#flnm=`aws s3 ls  digitalx-prod-order-report/Hourly --region=eu-west-1 --recursive|tail -1|awk  '{print $NF}'`
#aws s3 cp s3://digitalx-prod-order-report/${flnm} /opt/application/Jenkins_home/workspace/SUNRISE_CHK/HYPERCARE/order-report.csv
#sed -i '/SUBMITTED/ !d' /opt/application/Jenkins_home/workspace/SUNRISE_CHK/HYPERCARE/order-report.csv
#chmod 777 order-report.csv

#curl -X POST -H --silent --data-urlencode "payload={\"text\": \"$(cat status.txt)\"}" https://hooks.slack.com/services/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

