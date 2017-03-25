% -------------------------------------------------------------------------
%
% File : DynamicWindowApproachSample.m
%
% Discription : Mobile Robot Motion Planning with Dynamic Window Approach
%
% Environment : Matlab
%
% Author : John Lee
%
% Copyright (c): 2016 John Lee
%
% License : Modified BSD Software License Agreement
% -------------------------------------------------------------------------

function [] = DynamicWindowApproachSample()

close all;
clear all;
load ./Environment/obstacle_in_curve.mat
obstacle=obstaclematrix;

figSim=figure('NumberTitle','off','Name','Simulation');
figure(figSim);

%% Plot Obstacles %%%%%%%%%%%%%%%%
n=length(obstacle);
for i=1:n
    %straightline
    %      plotvehiclerectangle([obstacle(i,1),obstacle(i,2)],0,0.5,1,'y');hold on;
    %curve
    plotvehiclerectangle([obstacle(i,1),obstacle(i,2)],1,0.25,0.5,'y');hold on;
end
%curve
% plotvehiclerectangle([49.3,5],1,0.5,1,'y');hold on;
% plotvehiclerectangle([52.5,17],0.8,0.5,1,'y');

%% Display the Environment %%%%%%%%%%%%%%%%
% referencepath_xy=plotRoad2(figSim);%straightline
boundary_xy=plotCurveBoundary(figSim);%curveline
obstacle=[obstacle;boundary_xy];

disp('Dynamic Window Approach sample program start!!')


%% �������˶�ѧģ��
% ����ٶ�[m/s],�����ת�ٶ�[rad/s],���ٶ�[m/ss],��ת���ٶ�[rad/ss],
% �ٶȷֱ���[m/s],ת�ٷֱ���[rad/s]
Kinematic=[10.0,toRadian(30.0),6,toRadian(20.0),0.5,toRadian(1)];

x=[35 0 0 2 0]';% �����˵ĳ���״̬[x(m),y(m),yaw(Rad),v(m/s),w(rad/s)]
goal=[60,22];% Ŀ���λ�� [x(m),y(m)]
obstacleR=0.5;%0.5;% ��ͻ�ж��õ��ϰ���뾶
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
%C=eye(5);
x_predict(:,1)=x;
P_update(:,:,1)=eye(5);%��ʼ���Ż�����Э����
H=[1 0 0 0 0
    0 1 0 0 0];
%%ע����ǣ�Q��R��ֵ��Ӧ��Ϊ�̶�ֵ��Ŀǰ���������������������Ч���ܹ����˽��ܣ�
Q=[ 0.0438    0.0141         0         0         0
    0.0255    0.0266         0         0         0
         0         0         0         0         0
         0         0         0    1.0000         0
         0         0         0         0    1.0000];
     %mdiag(sqrt(0.01) * rand(2),0,eye(2));
R=[0.05,0;0,0.02];;%diag([0.3*rand(1),0.03*rand(1)]);
disp('Q');
disp(Q);
disp('R');
disp(R);

%% ���ۺ������� [heading,dist,velocity,predictDT]
evalParam=[0.05,0.2,0.1,3.0];
%area=[30 60 -15 15];% ģ������Χ [xmin xmax ymin ymax]

%% ģ��ʵ��Ľ��
result.x=[];
tic;
movcount=0;

%% Main loop
for i=2:5000
    % DWA��������
    [u,traj]=DynamicWindowApproach(x,Kinematic,goal,evalParam,obstacle,obstacleR);
    
    %% Use Kalman Filter to predict the state of robotic%%%%%%%%%%%%%%%%%%%%
    z(:,i)=C*x+0.01*normrnd(0,1);%normrnd(0,1); %ObservationEquation
   
    %-----1. Ԥ��-----
    %-----1.1 Ԥ��״̬-----
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
    
    %% ģ�����ı���
    x=x_update(:,i);
    P=inv(P_update(:,:,i));
    result.x=[result.x; x'];
    
    % �Ƿ񵽴�Ŀ�ĵ�
    if norm(x(1:2)-goal')<0.5
        disp('Arrive Goal!!');break;
    end
    
    %====Animation====
    %hold off;
    ArrowLength=3;
    % ������
    plotvehiclerectangle([x(1),x(2)],x(3),0.5,1,'y');
    
    %plot(result.x(:,1),result.x(:,2),'-b');hold on;
    %     plot(goal(1),goal(2),'*r');hold on;
    %     plot(obstacle(:,1),obstacle(:,2),'*k');hold on;
    
    % ̽���켣
        if ~isempty(traj)
            for it=1:length(traj(:,1))/5
                ind=1+(it-1)*5;
                plot(traj(ind,:),traj(ind+1,:),'-k');hold on;
            end
        end
    quiver(x(1),x(2),ArrowLength*cos(x(3)),ArrowLength*sin(x(3)),'r');hold on; %'ok' sets the line without arrow,the start point set to be 'o'
    % ����Э������󣨸�˹���ֵ��
    uncertain_u=[x(1) x(2)]';
    uncertain_P=P([1,2],[1,2]);
    r=chi2inv(0.95,2);%
    ellipsefig(uncertain_u,uncertain_P,r,1);% ��һ����Բ������(x-xc)'*P*(x-xc) = r
    
    axis([30,45,-5,5]);
    grid off;
    axis off;
    %text(35,2,'controlspace');
    drawnow;
    movcount=movcount+1;
    %mov(movcount) = getframe(gcf);%
end
toc
%movie2avi(mov,'motionplan.avi');


function [u,trajDB]=DynamicWindowApproach(x,model,goal,evalParam,ob,R)

% Dynamic Window [vmin,vmax,wmin,wmax]
Vr=CalcDynamicWindow(x,model);

% ���ۺ����ļ���
[evalDB,trajDB]=Evaluation(x,Vr,goal,ob,R,model,evalParam);

if isempty(evalDB)
    disp('no path to goal!!');
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
        if dist>stopDist %
            evalDB=[evalDB;[vt ot heading dist vel]];
            trajDB=[trajDB;traj];
        end
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
if dist>=2*R
    dist=2*R;
end

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