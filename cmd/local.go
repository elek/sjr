// Copyright (C) 2021 Storj Labs, Inc.
// See LICENSE for copying information.

package cmd

import (
	"github.com/compose-spec/compose-go/types"
	"github.com/spf13/cobra"

	"storj.io/storj-up/pkg/common"
)

func localCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "local",
		Short: "build local src directories for use inside the container",
		RunE: func(cmd *cobra.Command, args []string) error {
			composeProject, err := common.LoadComposeFromFile(common.ComposeFileName)
			if err != nil {
				return err
			}
			updatedComposeProject, err := common.UpdateEach(composeProject, buildLocalSrc, args[0], args[1:])
			if err != nil {
				return err
			}
			return common.WriteComposeFile(updatedComposeProject)
		},
	}
}

func init() {
	buildCmd.AddCommand(localCmd())
}

func buildLocalSrc(_ *types.ServiceConfig, _ string) error {
	// do magic here
	return nil
}
