function plot_state(SLAM, gt, trajectory, landmarks, timestep, z, window)
    % Visualizes the state of the FastSLAM algorithm.
    %
    % The resulting plot displays the following information:
    % - map ground truth (black +'s)
    % - currently best particle (red)
    % - particle set in green
    % - current landmark pose estimates (blue)
    % - visualization of the observations made at this time step (line between robot and landmark)
    clf; global err;
    hold on
    grid("on"); 
    %graphics_toolkit gnuplot
    L = struct2cell(landmarks);
    alpha   = 0.5;
    plot(cell2mat(L(2,:)), cell2mat(L(3,:)), 'o', 'color', [0,0,0] + alpha, 'markersize', 15, 'linewidth', 2);
    text(cell2mat(L(2,:)), cell2mat(L(3,:)), string(cell2mat(L(1,:))), 'FontSize', 8);

    % Plot the particles
    ppos = [SLAM.particle.pose];
    plot(ppos(1,:), ppos(2,:), 'g.');

    % determine the currently best particle
    [~, bestParticleIdx] = max([SLAM.particle.weight]);

    % draw the landmark locations along with the ellipsoids
    % Plot for FastSLAM with known data association
    if isfield(SLAM.particle(bestParticleIdx).landmark, 'isobserved')
        for i = 1:length(SLAM.particle(bestParticleIdx).landmark)
            if SLAM.particle(bestParticleIdx).landmark(i).isobserved
                l = SLAM.particle(bestParticleIdx).landmark(i).EKF.mu;
                plot(l(1), l(2), 'bo', 'markersize', 3);
                drawprobellipse(l, SLAM.particle(bestParticleIdx).landmark(i).EKF.Sigma, 0.95, 'b');
                
                % Extract landmarks estimation error
                err.mean(i,timestep)    = norm(l-[landmarks(i).x; landmarks(i).y],2);
                err.sig(i,timestep)     = err.sig(i,timestep) + sqrt(norm(SLAM.particle(bestParticleIdx).landmark(i).EKF.Sigma));
            end
        end
    % Plot for FastSLAM with unknown data association
    else
        for i = 1:length(SLAM.particle(bestParticleIdx).landmark)
            l = SLAM.particle(bestParticleIdx).landmark(i).EKF.mu;
            plot(l(1), l(2), 'bo', 'markersize', 3);
            drawprobellipse(l, SLAM.particle(bestParticleIdx).landmark(i).EKF.Sigma, 0.95, 'b');
        end
    end
    

    % draw the observations
    for i = 1:length(z)
        pose    = SLAM.particle(bestParticleIdx).pose;
        l_x     = pose(1) + z(i).range*cos(pose(3)+z(i).bearing);
        l_y     = pose(2) + z(i).range*sin(pose(3)+z(i).bearing);
        line([pose(1), l_x], [pose(2), l_y],...
            'color', 'r', 'LineStyle','--', 'linewidth', 1);
    end
        
    % draw the groud true trajectory
    line(gt(1,1:timestep), gt(2,1:timestep), 'color', 'cyan', 'linewidth', 2);

    % draw the trajectory as estimated by the currently best particle
    trajectory = [trajectory{bestParticleIdx,:}];
    line(trajectory(1,:), trajectory(2, :), 'color', 'k', 'LineStyle','-.', 'linewidth', 2);

    drawrobot(SLAM.particle(bestParticleIdx).pose, 'r', 3, 0.3, 0.3);
    xlim([-2, 12])
    ylim([-2, 12])

    hold off

    % dump to a file or show the window
    if window
        figure(1);
        drawnow;
        pause(0.1);
    else
        figure(1, "visible", "off");
        filename = sprintf('../plots/fastslam_%03d.png', timestep);
        print(filename, '-dpng');
    end
    
    % Plot error in final step
    if timestep == size(gt,2) && err.showErr
        set(gcf,'color','w');
        figure(2); grid on;
        subplot(2,1,1)
        plot(1:timestep, sum(err.mean~=0),'LineWidth',2);
        xlabel('Timestep'); ylabel({'Landmarks';'observed'}); set(gca,'FontSize',16);
        subplot(2,1,2)
        errorbar(1:timestep, sqrt(sum(err.mean.^2,1))./sum(err.mean~=0),...
                 sqrt(sum(err.sig.^2,1))./sum(err.mean~=0),'r-','LineWidth',0.2);
        xlabel('Timestep'); ylabel({'MSE of landmarks','estimation'}); set(gca,'FontSize',16);
        %errorbar(repmat(1:timestep,length(landmarks),1), err.mean,err.sig)
    end
end
