% -------------------------------------------------------------------------
%
% File : PredictionforTrafficParticipants.m
%
% Discription : Prediction of Vehicle with Dynamic Window Approach and
% Kalman Filter
%
% Environment : Matlab
%
% Author : John Lee
%
% Copyright (c): 2016 John Lee
%
% License : Modified BSD Software License Agreement
% -------------------------------------------------------------------------

function [PredictState,PredictVariance] = PredictionforTrafficParticipants(startpoint,destpoint,OtherObstacle,P_init,Q_init)

x=startpoint';%x=[30,0,0,3,0]';% �����˵ĳ���״̬[x(m),y(m),yaw(Rad),v(m/s),w(rad/s)]
goal=destpoint;%goal=[70,22];% Ŀ���λ�� [x(m),y(m)]
obstacle=OtherObstacle(:,1:2);
n=length(obstacle);
%P_update(:,:,1)=ones(5);
P_update(:,:,1)=P_init;

%%  Road Boundary Obstacles %%%%%%%%%%%%%%%%
%environmentFlag=0;%0:line,1:curveline
%boundary_xy=CalculateBoundary(environmentFlag);%curveline
%obstacle=[obstacle(1:2,:);boundary_xy];

%% �������˶�ѧģ��
% ����ٶ�[m/s],�����ת�ٶ�[rad/s],���ٶ�[m/ss],��ת���ٶ�[rad/ss],
% �ٶȷֱ���[m/s],ת�ٷֱ���[rad/s]
Kinematic=[10.0,toRadian(30.0),1,toRadian(20.0),0.05,toRadian(1)];
obstacleR = 0.5;% ��ͻ�ж��õ��ϰ���뾶
global dt; dt=0.1;% ʱ��[s]
A = [1 0 0 0 0
    0 1 0 0 0
    0 0 1 0 0
    0 0 0 0 0
    0 0 0 0 0];
B = [dt*cos(x(3)) 0
    dt*sin(x(3)) 0
    0 dt
    1 0
    0 1];
C =[1 0 0 0 0
    0 1 0 0 0];
x_predict(:,1)=x;
H=[1 0 0 0 0
    0 1 0 0 0];
Q=Q_init;
% Q = mdiag([0.5,0;0,0.4],0,eye(2));%mdiag(0.5*diag([abs(randn(1)),abs(randn(1))]),0,eye(2));
% R = [0.5,0;0,0.02];%diag([0.3*rand(1),0.03*rand(1)]);
%Q=mdiag([0.0438,0.0141;0.0255,0.0266],0,eye(2));
R=[0.05,0;0,0.02];;%diag([0.3*rand(1),0.03*rand(1)]);
mu = [0 0]; Sigma = R;

%% ���ۺ������� [heading,dist,velocity,predictDT]
evalParam=[0.05,0.2,0.1,0.5];%predictDT=3.0
%area=[30 60 -15 15];% ģ������Χ [xmin xmax ymin ymax]

%% DWA Approach
%disp('Dynamic Window Approach sample program start!!')
i=2;
[u,traj]=DynamicWindowApproach(x,Kinematic,goal,evalParam,obstacle,obstacleR);
% disp('u');disp(u);
% disp('traj');disp(traj);
%% Use Kalman Filter to predict the state of robotic%%%%%%%%%%%%%%%%%%%%
% ���Ϊ������̫�ֲ����������
r = mvnrnd(mu, Sigma, 1)';
z(:,i)=C*x+r;%normrnd(0,1); %ObservationEquation
% ���Ϊһ����С�����ֵ�������ܱ���Ҳ��Ȼ��P��Qֵ��ѡ���нϴ��Ӱ�죡
% z(:,i)=C*x+0.01*normrnd(0,1); %ObservationEquation
%-----1. Ԥ��-----
%-----1.1 Ԥ��״̬-----
u_record(:,i)=u;
x_predict(:,i)=f(x,u);% �������ƶ�����һ��ʱ��
%-----1.2 Ԥ�����Э����-----
P_predict(:,:,i)=A*P_update(:,:,i-1)*A'+Q;%p1Ϊһ�����Ƶ�Э�����ʽ��t-1ʱ�����Ż�����s��Э����õ�t-1ʱ�̵�tʱ��һ�����Ƶ�Э����

%-----2. ����-----
%-----2.1 ���㿨��������-----
K(:,:,i)=P_predict(:,:,i)*H' / (H*P_predict(:,:,i)*H'+R);%K(t)Ϊ���������棬�������ʾΪ������Ԥ���Ȩ�ر�
%-----2.2 ����״̬-----
x_update(:,i)=x_predict(:,i)  +  K(:,:,i) * (z(:,i)-H*x_predict(:,i));%Y(t)-a*c*s(t-1)��֮Ϊ��Ϣ���ǹ۲�ֵ��һ�����Ƶõ��Ĺ۲�ֵ֮���ʽ����һʱ��״̬�����Ż�����s(t-1)�õ���ǰʱ�̵����Ż�����s(t)
%-----2.3 �������Э����-----
P_update(:,:,i)=P_predict(:,:,i) - K(:,:,i)*H*P_predict(:,:,i);%��ʽ��һ�����Ƶ�Э����õ���ʱ�����Ż����Ƶ�Э����

%% ���������
x=x_update(:,i);
P=inv(P_update(:,:,i));
% if norm(x(1:2)-goal')<0.5
%     disp('Watch out for collision!!');break;
% end
% Ԥ����ʻ�켣
ArrowLength=3;
%quiver(x(1),x(2),ArrowLength*cos(x(3)),ArrowLength*sin(x(3)),'ok');hold on; %'ok' sets the line without arrow,the start point set to be 'o'
%̽���켣
% if ~isempty(traj)
%     for it=1:length(traj(:,1))/5
%         ind=1+(it-1)*5;
%         plot(traj(ind,:),traj(ind+1,:),'*g');hold on;
%     end
% end

% Ԥ�Ʒֲ���Χ [����Э������󣨸�˹���ֵ��]
uncertain_u=[x(1) x(2)]';
uncertain_P=P([1,2],[1,2]);
r=chi2inv(0.95,2);
ellipsefig(uncertain_u,uncertain_P,r,1);% ��һ����Բ������(x-xc)'*P*(x-xc) = r
drawnow;
% ������
PredictState=x;
PredictVariance=P;
%disp('PredictVariance');disp(PredictVariance);

function [u,trajDB]=DynamicWindowApproach(x,model,goal,evalParam,ob,R)

% Dynamic Window [vmin,vmax,wmin,wmax]
Vr=CalcDynamicWindow(x,model);

% ���ۺ����ļ���
[evalDB,trajDB]=Evaluation(x,Vr,goal,ob,R,model,evalParam);

if isempty(evalDB)
    u=[0;0];return;
end

% �����ۺ�������
evalDB=NormalizeEval(evalDB);

% �������ۺ����ļ���
feval=[];
for id=1:length(evalDB(:,1))
    feval=[feval;evalParam(1:3)*evalDB(id,3:5)'];
end
evalDB=[evalDB feval];

[maxv,ind]=max(feval);% �������ۺ���
u=evalDB(ind,1:2)';%

function [evalDB,trajDB]=Evaluation(x,Vr,goal,ob,R,model,evalParam)
%
evalDB=[];
trajDB=[];
for vt=Vr(1):model(5):Vr(2)
    for ot=Vr(3):model(6):Vr(4)
        % �켣�Ʋ�; �õ� xt: ��������ǰ�˶����Ԥ��λ��; traj: ��ǰʱ�� �� Ԥ��ʱ��֮��Ĺ켣
        [xt,traj]=GenerateTrajectory(x,vt,ot,evalParam(4),model);  %evalParam(4),ǰ��ģ��ʱ��;
        % �����ۺ����ļ���
        heading=CalcHeadingEval(xt,goal);
        dist=CalcDistEval(xt,ob,R);
        vel=abs(vt);
        % �ƶ�����ļ���
        stopDist=CalcBreakingDist(vel,model);
        evalDB=[evalDB;[vt ot heading dist vel]];
        trajDB=[trajDB;traj];
%         if dist>stopDist %
%         end
    end
end

function EvalDB=NormalizeEval(EvalDB)
% ���ۺ�������
if sum(EvalDB(:,3))~=0
    EvalDB(:,3)=EvalDB(:,3)/sum(EvalDB(:,3));
end
if sum(EvalDB(:,4))~=0
    EvalDB(:,4)=EvalDB(:,4)/sum(EvalDB(:,4));
end
if sum(EvalDB(:,5))~=0
    EvalDB(:,5)=EvalDB(:,5)/sum(EvalDB(:,5));
end

function [x,traj]=GenerateTrajectory(x,vt,ot,evaldt,model)
% �켣���ɺ���
% evaldt��ǰ��ģ��ʱ��; vt��ot��ǰ�ٶȺͽ��ٶ�;
global dt;
time=0;
u=[vt;ot];% ����ֵ
traj=x;% �����˹켣
while time<=evaldt
    time=time+dt;% ʱ�����
    x=f(x,u);% �˶�����
    traj=[traj x];
end

function stopDist=CalcBreakingDist(vel,model)
% �����˶�ѧģ�ͼ����ƶ�����,����ƶ����벢û�п�����ת�ٶȣ�����ȷ�ɣ�����
global dt;
stopDist=0;
while vel>0
    stopDist=stopDist+vel*dt;% �ƶ�����ļ���
    vel=vel-model(3)*dt;%
end

function dist=CalcDistEval(x,ob,R)
% �ϰ���������ۺ���
dist=100;
for io=1:length(ob(:,1))
    disttmp=norm(ob(io,:)-x(1:2)')-R;
    if dist>disttmp% ���ϰ�����С�ľ���
        dist=disttmp;
    end
end
% �ϰ�����������޶�һ�����ֵ��������趨��һ��һ���켣û���ϰ����̫ռ����
% if dist>=2*R
%     dist=2*R;
% end


function heading=CalcHeadingEval(x,goal)
% heading�����ۺ�������

theta=toDegree(x(3));% �����˳���
goalTheta=toDegree(atan2(goal(2)-x(2),goal(1)-x(1)));% Ŀ���ķ�λ

if goalTheta>theta
    targetTheta=goalTheta-theta;% [deg]
else
    targetTheta=theta-goalTheta;% [deg]
end

heading=180-targetTheta;

function Vr=CalcDynamicWindow(x,model)
%
global dt;
% �����ٶȵ������С��Χ
Vs=[0 model(1) -model(2) model(2)];

% ���ݵ�ǰ�ٶ��Լ����ٶ����Ƽ���Ķ�̬����
Vd=[x(4)-model(3)*dt x(4)+model(3)*dt x(5)-model(4)*dt x(5)+model(4)*dt];

% ���յ�Dynamic Window
Vtmp=[Vs;Vd];
Vr=[max(Vtmp(:,1)) min(Vtmp(:,2)) max(Vtmp(:,3)) min(Vtmp(:,4))];

function x = f(x, u)
% Motion Model
% u = [vt; ot];��ǰʱ�̲������ٶȡ����ٶ�
global dt;
A = [1 0 0 0 0
    0 1 0 0 0
    0 0 1 0 0
    0 0 0 0 0
    0 0 0 0 0];

B = [dt*cos(x(3)) 0
    dt*sin(x(3)) 0
    0 dt
    1 0
    0 1];

x= A*x+B*u;

function radian = toRadian(degree)
% degree to radian
radian = degree/180*pi;

function degree = toDegree(radian)
% radian to degree
degree = radian/pi*180;



