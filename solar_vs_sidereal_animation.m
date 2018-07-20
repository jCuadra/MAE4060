function solar_vs_sidereal_animation(varargin)

%input parsing
p = inputParser;
addOptional(p,'ndays', 1, @(x) isnumeric(x) && x>=0);
addParameter(p,'daytype', 'sidereal', @(x) strcmpi(x,'sidereal') || strcmpi(x,'solar'));
addParameter(p,'animlength', 10, @(x) isnumeric(x) && x>=0);
parse(p,varargin{:});
nframes = 30*p.Results.animlength; %30 fps 

%constants
R_E = 6378.1366*1000; %Earth radius (m)
mAU = 149597870700; %AU in m

a = 1.00000261;  %semi-major axis (AU)
a = a*mAU/R_E; %Earth radii

e = 0.01671123;  %eccentricity
I = -0.00001531 * pi/180.; %inclination (rad)
L = 100.46457166 * pi/180; %mean longitude (rad)
varpi = 102.93768193 * pi/180; %long. of periapsis (rad)
Omega = 0; %long. of asending node (rad)
omega = varpi - Omega; %argument of periapsis (rad)

w_e = 7.2921150e-5; %Earth rotation (rad/s) 

musun = 1.32712440018e20; %m^3/s^2
sun_EM = 328900.56; %mass ratio: sun/(Earth+Moon)
mu = (1 + 1/sun_EM)*musun/(R_E^3); %Earth rad^3/s^2;
n = sqrt(mu/a^3); %s^(-1)
T_p = 2*pi/n; %orbital period in s

%define time array
if strcmpi(p.Results.daytype, 'sidereal')
    t = linspace(0,p.Results.ndays*2*pi/w_e,nframes); %sidereal days
else
    t = linspace(0,p.Results.ndays*86400,nframes); %solar day
end

M = n*t;
E = invKepler(M,e);
E = E.';

A = [a.*(cos(Omega).*cos(omega) - sin(Omega).*cos(I).*sin(omega));...
    a.*(sin(Omega).*cos(omega) + cos(Omega).*cos(I).*sin(omega));...
    a.*sin(I).*sin(omega)];

B = [-a.*sqrt(1-e.^2).*(cos(Omega).*sin(omega) + ...
    sin(Omega).*cos(I).*cos(omega));...
    a.*sqrt(1-e.^2).*(-sin(Omega).*sin(omega) + ...
    cos(Omega).*cos(I).*cos(omega));...
    a.*sqrt(1-e.^2).*sin(I).*cos(omega)];

r = A*(cos(E) - e) + B*(sin(E)); %orbit path (r_E/Sun) in ecliptic coords

vareps = 84381.412/3600*pi/180; %as->rad
rotMat = [1 0 0; 0 cos(vareps) -sin(vareps); 0 sin(vareps) cos(vareps)]; %eclip->equat
rsun = -rotMat*r; %r_Sun/E in equatorial coords

%%
load('topo.mat','topo','topomap1');
earth = imread('landOcean.jpg');

f1 = figure(1);
clf

[x,y,z] = sphere(50);
props.AmbientStrength = 0;  %0
props.DiffuseStrength = 1;
props.SpecularColorReflectance = .5;
props.SpecularExponent = 1;
props.SpecularStrength = 0.2;
props.FaceColor= 'texture';
props.EdgeColor = 'none';
props.FaceLighting = 'phong';
%props.Cdata = topo;
props.Cdata = earth;
Earth = surface(x,y,flip(z),props);
%rotate(Earth,[0,0,1],180) %align prime meridian 
hold on
g = hgtransform;
oax = quiver3([0,0,0],[0,0,0],[0,0,0],[1.5,0,0],[0,1.5,0],[0,0,1.5],0,'Linewidth',2,'color','r');
eax = quiver3([0,0,0],[0,0,0],[0,0,0],[1.5,0,0],[0,1.5,0],[0,0,1.5],0,'Linewidth',2,'Parent',g,'color','b');
hold off
Earth.Parent = g;
view(50,10)
axis([-1.5,1.5,-1.5,1.5,-1.5,1.5])
axis equal off
%colormap(topomap1)

% Add sun
sun = light('position',rsun(:,1));
ax1 = gca;

%%

for j = 2:length(t)
    set(g,'Matrix',makehgtform('zrotate',w_e*t(j)))
    pause(1/30)
    set(sun,'Position',rsun(:,j))
end